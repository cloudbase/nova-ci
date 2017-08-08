Param(
    [Parameter(Mandatory=$True)]
    [string]$serviceUsername,
    [Parameter(Mandatory=$True)]
    [string]$servicePassword
)

<#
Copyright 2012 Aaron Jensen (Carbon C# code)
Copyright 2014 Cloudbase Solutions Srl (PowerShell script)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#>

$Source = @"
/*
Original sources available at: https://bitbucket.org/splatteredbits/carbon
*/

using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Text;

namespace PSCarbon
{
    public sealed class Lsa
    {
        // ReSharper disable InconsistentNaming
        [StructLayout(LayoutKind.Sequential)]
        internal struct LSA_UNICODE_STRING
        {
            internal LSA_UNICODE_STRING(string inputString)
            {
                if (inputString == null)
                {
                    Buffer = IntPtr.Zero;
                    Length = 0;
                    MaximumLength = 0;
                }
                else
                {
                    Buffer = Marshal.StringToHGlobalAuto(inputString);
                    Length = (ushort)(inputString.Length * UnicodeEncoding.CharSize);
                    MaximumLength = (ushort)((inputString.Length + 1) * UnicodeEncoding.CharSize);
                }
            }

            internal ushort Length;
            internal ushort MaximumLength;
            internal IntPtr Buffer;
        }

        [StructLayout(LayoutKind.Sequential)]
        internal struct LSA_OBJECT_ATTRIBUTES
        {
            internal uint Length;
            internal IntPtr RootDirectory;
            internal LSA_UNICODE_STRING ObjectName;
            internal uint Attributes;
            internal IntPtr SecurityDescriptor;
            internal IntPtr SecurityQualityOfService;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct LUID
        {
            public uint LowPart;
            public int HighPart;
        }

        // ReSharper disable UnusedMember.Local
        private const uint POLICY_VIEW_LOCAL_INFORMATION = 0x00000001;
        private const uint POLICY_VIEW_AUDIT_INFORMATION = 0x00000002;
        private const uint POLICY_GET_PRIVATE_INFORMATION = 0x00000004;
        private const uint POLICY_TRUST_ADMIN = 0x00000008;
        private const uint POLICY_CREATE_ACCOUNT = 0x00000010;
        private const uint POLICY_CREATE_SECRET = 0x00000014;
        private const uint POLICY_CREATE_PRIVILEGE = 0x00000040;
        private const uint POLICY_SET_DEFAULT_QUOTA_LIMITS = 0x00000080;
        private const uint POLICY_SET_AUDIT_REQUIREMENTS = 0x00000100;
        private const uint POLICY_AUDIT_LOG_ADMIN = 0x00000200;
        private const uint POLICY_SERVER_ADMIN = 0x00000400;
        private const uint POLICY_LOOKUP_NAMES = 0x00000800;
        private const uint POLICY_NOTIFICATION = 0x00001000;
        // ReSharper restore UnusedMember.Local

        [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern bool LookupPrivilegeValue(
            [MarshalAs(UnmanagedType.LPTStr)] string lpSystemName,
            [MarshalAs(UnmanagedType.LPTStr)] string lpName,
            out LUID lpLuid);

        [DllImport("advapi32.dll", CharSet = CharSet.Unicode)]
        private static extern uint LsaAddAccountRights(
            IntPtr PolicyHandle,
            IntPtr AccountSid,
            LSA_UNICODE_STRING[] UserRights,
            uint CountOfRights);

        [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = false)]
        private static extern uint LsaClose(IntPtr ObjectHandle);

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern uint LsaEnumerateAccountRights(IntPtr PolicyHandle,
            IntPtr AccountSid,
            out IntPtr UserRights,
            out uint CountOfRights
            );

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern uint LsaFreeMemory(IntPtr pBuffer);

        [DllImport("advapi32.dll")]
        private static extern int LsaNtStatusToWinError(long status);

        [DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
        private static extern uint LsaOpenPolicy(ref LSA_UNICODE_STRING SystemName, ref LSA_OBJECT_ATTRIBUTES ObjectAttributes, uint DesiredAccess, out IntPtr PolicyHandle );

        [DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
        static extern uint LsaRemoveAccountRights(
            IntPtr PolicyHandle,
            IntPtr AccountSid,
            [MarshalAs(UnmanagedType.U1)]
            bool AllRights,
            LSA_UNICODE_STRING[] UserRights,
            uint CountOfRights);
        // ReSharper restore InconsistentNaming

        private static IntPtr GetIdentitySid(string identity)
        {
            var sid =
                new NTAccount(identity).Translate(typeof (SecurityIdentifier)) as SecurityIdentifier;
            if (sid == null)
            {
                throw new ArgumentException(string.Format("Account {0} not found.", identity));
            }
            var sidBytes = new byte[sid.BinaryLength];
            sid.GetBinaryForm(sidBytes, 0);
            var sidPtr = Marshal.AllocHGlobal(sidBytes.Length);
            Marshal.Copy(sidBytes, 0, sidPtr, sidBytes.Length);
            return sidPtr;
        }

        private static IntPtr GetLsaPolicyHandle()
        {
            var computerName = Environment.MachineName;
            IntPtr hPolicy;
            var objectAttributes = new LSA_OBJECT_ATTRIBUTES
            {
                Length = 0,
                RootDirectory = IntPtr.Zero,
                Attributes = 0,
                SecurityDescriptor = IntPtr.Zero,
                SecurityQualityOfService = IntPtr.Zero
            };

            const uint ACCESS_MASK = POLICY_CREATE_SECRET | POLICY_LOOKUP_NAMES | POLICY_VIEW_LOCAL_INFORMATION;
            var machineNameLsa = new LSA_UNICODE_STRING(computerName);
            var result = LsaOpenPolicy(ref machineNameLsa, ref objectAttributes, ACCESS_MASK, out hPolicy);
            HandleLsaResult(result);
            return hPolicy;
        }

        public static string[] GetPrivileges(string identity)
        {
            var sidPtr = GetIdentitySid(identity);
            var hPolicy = GetLsaPolicyHandle();
            var rightsPtr = IntPtr.Zero;

            try
            {

                var privileges = new List<string>();

                uint rightsCount;
                var result = LsaEnumerateAccountRights(hPolicy, sidPtr, out rightsPtr, out rightsCount);
                var win32ErrorCode = LsaNtStatusToWinError(result);
                // the user has no privileges
                if( win32ErrorCode == STATUS_OBJECT_NAME_NOT_FOUND )
                {
                    return new string[0];
                }
                HandleLsaResult(result);

                var myLsaus = new LSA_UNICODE_STRING();
                for (ulong i = 0; i < rightsCount; i++)
                {
                    var itemAddr = new IntPtr(rightsPtr.ToInt64() + (long) (i*(ulong) Marshal.SizeOf(myLsaus)));
                    myLsaus = (LSA_UNICODE_STRING) Marshal.PtrToStructure(itemAddr, myLsaus.GetType());
                    var cvt = new char[myLsaus.Length/UnicodeEncoding.CharSize];
                    Marshal.Copy(myLsaus.Buffer, cvt, 0, myLsaus.Length/UnicodeEncoding.CharSize);
                    var thisRight = new string(cvt);
                    privileges.Add(thisRight);
                }
                return privileges.ToArray();
            }
            finally
            {
                Marshal.FreeHGlobal(sidPtr);
                var result = LsaClose(hPolicy);
                HandleLsaResult(result);
                result = LsaFreeMemory(rightsPtr);
                HandleLsaResult(result);
            }
        }

        public static void GrantPrivileges(string identity, string[] privileges)
        {
            var sidPtr = GetIdentitySid(identity);
            var hPolicy = GetLsaPolicyHandle();

            try
            {
                var lsaPrivileges = StringsToLsaStrings(privileges);
                var result = LsaAddAccountRights(hPolicy, sidPtr, lsaPrivileges, (uint)lsaPrivileges.Length);
                HandleLsaResult(result);
            }
            finally
            {
                Marshal.FreeHGlobal(sidPtr);
                var result = LsaClose(hPolicy);
                HandleLsaResult(result);
            }
        }

        const int STATUS_SUCCESS = 0x0;
        const int STATUS_OBJECT_NAME_NOT_FOUND = 0x00000002;
        const int STATUS_ACCESS_DENIED = 0x00000005;
        const int STATUS_INVALID_HANDLE = 0x00000006;
        const int STATUS_UNSUCCESSFUL = 0x0000001F;
        const int STATUS_INVALID_PARAMETER = 0x00000057;
        const int STATUS_NO_SUCH_PRIVILEGE = 0x00000521;
        const int STATUS_INVALID_SERVER_STATE = 0x00000548;
        const int STATUS_INTERNAL_DB_ERROR = 0x00000567;
        const int STATUS_INSUFFICIENT_RESOURCES = 0x000005AA;

        private static readonly Dictionary<int, string> ErrorMessages = new Dictionary<int, string>
                                    {
                                        {STATUS_OBJECT_NAME_NOT_FOUND, "Object name not found. An object in the LSA policy database was not found. The object may have been specified either by SID or by name, depending on its type."},
                                        {STATUS_ACCESS_DENIED, "Access denied. Caller does not have the appropriate access to complete the operation."},
                                        {STATUS_INVALID_HANDLE, "Invalid handle. Indicates an object or RPC handle is not valid in the context used."},
                                        {STATUS_UNSUCCESSFUL, "Unsuccessful. Generic failure, such as RPC connection failure."},
                                        {STATUS_INVALID_PARAMETER, "Invalid parameter. One of the parameters is not valid."},
                                        {STATUS_NO_SUCH_PRIVILEGE, "No such privilege. Indicates a specified privilege does not exist."},
                                        {STATUS_INVALID_SERVER_STATE, "Invalid server state. Indicates the LSA server is currently disabled."},
                                        {STATUS_INTERNAL_DB_ERROR, "Internal database error. The LSA database contains an internal inconsistency."},
                                        {STATUS_INSUFFICIENT_RESOURCES, "Insufficient resources. There are not enough system resources (such as memory to allocate buffers) to complete the call."}
                                    };

        private static void HandleLsaResult(uint returnCode)
        {
            var win32ErrorCode = LsaNtStatusToWinError(returnCode);

            if( win32ErrorCode == STATUS_SUCCESS)
                return;

            if( ErrorMessages.ContainsKey(win32ErrorCode) )
            {
                throw new Win32Exception(win32ErrorCode, ErrorMessages[win32ErrorCode]);
            }

            throw new Win32Exception(win32ErrorCode);
        }

        public static void RevokePrivileges(string identity, string[] privileges)
        {
            var sidPtr = GetIdentitySid(identity);
            var hPolicy = GetLsaPolicyHandle();

            try
            {
                var currentPrivileges = GetPrivileges(identity);
                if (currentPrivileges.Length == 0)
                {
                    return;
                }
                var lsaPrivileges = StringsToLsaStrings(privileges);
                var result = LsaRemoveAccountRights(hPolicy, sidPtr, false, lsaPrivileges, (uint)lsaPrivileges.Length);
                HandleLsaResult(result);
            }
            finally
            {
                Marshal.FreeHGlobal(sidPtr);
                var result = LsaClose(hPolicy);
                HandleLsaResult(result);
            }

        }

        private static LSA_UNICODE_STRING[] StringsToLsaStrings(string[] privileges)
        {
            var lsaPrivileges = new LSA_UNICODE_STRING[privileges.Length];
            for (var idx = 0; idx < privileges.Length; ++idx)
            {
                lsaPrivileges[idx] = new LSA_UNICODE_STRING(privileges[idx]);
            }
            return lsaPrivileges;
        }
    }
}
"@

Add-Type -TypeDefinition $Source -Language CSharp

$ServiceChangeErrors = @{}
$ServiceChangeErrors.Add(1, "Not Supported")
$ServiceChangeErrors.Add(2, "Access Denied")
$ServiceChangeErrors.Add(3, "Dependent Services Running")
$ServiceChangeErrors.Add(4, "Invalid Service Control")
$ServiceChangeErrors.Add(5, "Service Cannot Accept Control")
$ServiceChangeErrors.Add(6, "Service Not Active")
$ServiceChangeErrors.Add(7, "Service Request Timeout")
$ServiceChangeErrors.Add(8, "Unknown Failure")
$ServiceChangeErrors.Add(9, "Path Not Found")
$ServiceChangeErrors.Add(10, "Service Already Running")
$ServiceChangeErrors.Add(11, "Service Database Locked")
$ServiceChangeErrors.Add(12, "Service Dependency Deleted")
$ServiceChangeErrors.Add(13, "Service Dependency Failure")
$ServiceChangeErrors.Add(14, "Service Disabled")
$ServiceChangeErrors.Add(15, "Service Logon Failure")
$ServiceChangeErrors.Add(16, "Service Marked For Deletion")
$ServiceChangeErrors.Add(17, "Service No Thread")
$ServiceChangeErrors.Add(18, "Status Circular Dependency")
$ServiceChangeErrors.Add(19, "Status Duplicate Name")
$ServiceChangeErrors.Add(20, "Status Invalid Name")
$ServiceChangeErrors.Add(21, "Status Invalid Parameter")
$ServiceChangeErrors.Add(22, "Status Invalid Service Account")
$ServiceChangeErrors.Add(23, "Status Service Exists")
$ServiceChangeErrors.Add(24, "Service Already Paused")

$openstackDir = "C:\OpenStack"
$virtualenv = "C:\Python27"
$configDir = "$openstackDir\etc"
$downloadLocation = "http://144.76.59.195:8088"

$novaServiceName = "nova-compute"
$novaServiceDescription = "OpenStack nova Compute Service"
$novaServiceExecutable = "$virtualenv\Scripts\nova-compute.exe"
$novaServiceConfig = "$configDir\nova.conf"

$neutronServiceName = "neutron-hyperv-agent"
$neutronServiceDescription = "OpenStack Neutron Hyper-V Agent Service"
$neutronServiceExecutable = "$virtualenv\Scripts\neutron-hyperv-agent.exe"
$neutronServiceConfig = "$configDir\neutron_hyperv_agent.conf"

function SetUserLogonAsServiceRights($UserName)
{
    $privilege = "SeServiceLogonRight"
    if (![PSCarbon.Lsa]::GetPrivileges($UserName).Contains($privilege))
    {
        [PSCarbon.Lsa]::GrantPrivileges($UserName, $privilege)
    }
}

Function Set-ServiceAcctCreds
{
    Param(
        [string]$serviceName
    )

    $filter = 'Name=' + "'" + $serviceName + "'" + ''
    $service = Get-WMIObject -namespace "root\cimv2" -class Win32_Service -Filter $filter
    $service.StopService()
    while ($service.Started)
    {
        sleep 2
        $service = Get-WMIObject -namespace "root\cimv2" -class Win32_Service -Filter $filter
    }

    if ((Get-WMIObject -namespace "root\cimv2" -class Win32_ComputerSystem).partofdomain -eq $true) 
    {
        $hostname = (Get-WmiObject Win32_ComputerSystem).Domain
    } else {
        $hostname = hostname
    }

    SetUserLogonAsServiceRights "$hostname\$serviceUsername"

    $service.Change($null,$null,$null,$null,$null,$null,"$hostname\$serviceUsername",$servicePassword)
}

Function Check-Service
{
    Param(
        [string]$serviceName,
        [string]$serviceDescription,
        [string]$serviceExecutable,
        [string]$serviceConfig
    )

    $serviceFileLocation = "$openstackDir\service"
    $serviceFileName = "OpenStackService.exe"
    $serviceStartMode = "Manual"
    $filter='Name=' + "'" + $serviceName + "'"

    #Temporary hack
	
    Stop-Service $serviceName
	
    $service=Get-WmiObject -namespace "root\cimv2" -Class Win32_Service -Filter $filter
    if($service)
    {
        $service.delete()
    }
    #to make sure the service was actually deleted
    if (Get-Service $serviceName -ErrorAction SilentlyContinue){
	Write-Host "Service $serviceName failed deletion"
    }
    else
    {
	Write-Host "Service $serviceName succesfully deleted"
    }

    $hasServiceFileFolder = Test-Path $serviceFileLocation
    $hasServiceFile = Test-Path "$serviceFileLocation\$serviceFileName"
    $hasService = Get-Service $serviceName -ErrorAction SilentlyContinue
    $hasCorrectUser = (Get-WmiObject -namespace "root\cimv2" -class Win32_Service -Filter $filter).StartName -like "*$serviceUsername*"

    Write-Host "Initial status for $serviceName is:"
    Write-Host "hasServiceFileFolder: $hasServiceFileFolder"
    Write-Host "hasServiceFile: $hasServiceFile"
    Write-Host "hasService: $hasService"
    Write-Host "hasCorrectUser: $hasCorrectUser"

    if(!$hasServiceFileFolder)
    {
        Try
        {
            New-Item -Path $serviceFileLocation -ItemType directory
        }
        Catch
        {
            Throw "Can't create service file folder"
        }
    }
    else 
    {
        Write-Host "Service File folder exists"
    }

    if(!$hasServiceFile)
    {
        Try
        {
            Invoke-WebRequest -Uri "$downloadLocation/$serviceFileName" -OutFile "$serviceFileLocation\$serviceFileName"
        }
        Catch
        {
            Throw "Error downloading the service file executable."
        }
    }
    else 
    {
        Write-Host "Service file executable exists"
    }

    if(!$hasService)
    {
        Try
        {
            New-Service -name "$serviceName" -binaryPathName "`"$serviceFileLocation\$serviceFileName`" $serviceName `"$serviceExecutable`" --config-file `"$serviceConfig`"" -displayName "$serviceName" -description "$serviceDescription" -startupType $serviceStartMode
        }
        Catch
        {
            Throw "Error creating the service $serviceName"
        }
    }
    else 
    {
        Write-Host "Service $serviceName already registered"
    }

    if((Get-Service -Name $serviceName).Status -eq "Running")
    {
        Stop-Service $serviceName
        Write-Host "Service $serviceName was found in Running state."
        Write-Host "Current $serviceName state is: $((Get-Service -Name $serviceName).Status)"
    }

    if(!$hasCorrectUser)
    {
        Try
        {
            Set-ServiceAcctCreds $serviceName
        }
        Catch
        {
            Throw "Error setting service account credentials for $serviceName"
        }
    }
    else 
    {
        Write-Host "Service $serviceName already has correct user credentials."
    }
}

Check-Service $novaServiceName $novaServiceDescription $novaServiceExecutable $novaServiceConfig

Check-Service $neutronServiceName $neutronServiceDescription $neutronServiceExecutable $neutronServiceConfig
