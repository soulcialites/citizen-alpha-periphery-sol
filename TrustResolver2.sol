// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IDeployer {
    function getNations() external view returns (address[] memory);

    function getNationCount() external view returns (uint256);
} 

interface INation {
    function getCitizenAlpha() external view returns (address);

    function hasRole(bytes32 role, address citizen) external view returns(bool);
}

interface ICitizenAlpha1 {
    function ownerOf(uint256 _id) external view returns (address owner);

    function issue(address _citizen) external;

    function revoke(address _citizen) external;

    function getId(address citizen) external view returns (uint256);

    function getLink(address citizen) external view returns (address issuer);

    function hasRole(bytes32 role, address citizen) external view returns (bool);

    function isCitizen(address citizen) external view returns (bool status);
}


contract TrustResolver2 {

    address private immutable _deployer;
    bytes32[] private _roles;
    mapping(bytes32 => bool) private _roleExists;

    struct NationRole {
        address nation;
        bytes32 role;
    }

    constructor(address _deployer_) {
        _deployer = _deployer_;
        _roles.push(0x00);
        _roles.push(keccak256("FOUNDER"));
        _roles.push(keccak256("GOVERNANCE"));
        _roleExists[0x00] = true;
        _roleExists[keccak256("FOUNDER")] = true;
        _roleExists[keccak256("GOVERNANCE")] = true;
    }

    function getRoles() public view returns(bytes32[] memory) {
        return _roles;
    }

    function addRole(bytes32 _newRole) public {
        if (!_roleExists[_newRole]) {
            _roles.push(_newRole);
            _roleExists[_newRole] = true;
        }
    }


    function _getCitizenNationRoles(address citizen, address nation) private view returns(bytes32[] memory) {
        uint rolesCount = _roles.length;
        bytes32[] memory citizenRolesTemp = new bytes32[](rolesCount);
        uint256 citizenRolesCount = 0;
        for (uint256 i=0; i < rolesCount; i++) {
            bytes32 currentRole = _roles[i];
            if (INation(nation).hasRole(currentRole, citizen)) {
                citizenRolesTemp[citizenRolesCount] = currentRole;
                citizenRolesCount++;
            }
        }
        if (citizenRolesCount == 0) {
            return new bytes32[](0);
        }
        else {
            bytes32[] memory citizenRoles = new bytes32[](citizenRolesCount);
            for (uint256 i=0; i < citizenRolesCount; i++) {
                citizenRoles[i] = citizenRolesTemp[i];
            }
            return citizenRoles;
        }
    }

    function getCitizenNationRoles(address citizen, address nation) public view returns(bytes32[] memory) {
        return _getCitizenNationRoles(citizen, nation);
    }

    function getCitizenNationsRoles(address citizen) public view returns(NationRole[] memory) {
        uint nationsCount = IDeployer(_deployer).getNationCount();
        address[] memory nations = IDeployer(_deployer).getNations();
        uint rolesCount = _roles.length;
        NationRole[] memory resultsTemp = new NationRole[](nationsCount * rolesCount);
        uint256 count = 0;
        for (uint256 i = 0; i < nationsCount; i++) {
            address nationAddress = nations[i];
            bytes32[] memory citizenNationRolesTemp = _getCitizenNationRoles(citizen, nationAddress);
            for (uint256 j = 0; j < citizenNationRolesTemp.length; j++) {
                resultsTemp[count] = NationRole({nation: nationAddress, role: citizenNationRolesTemp[j]});
                count++;
            } 
        }
        if (count == 0) {
            return new NationRole[](0);
        }
        else {
            NationRole[] memory citizenNationsRoles = new NationRole[](count);
            for (uint i = 0; i < count; i ++) {
                citizenNationsRoles[i] = resultsTemp[i];
            }
            return citizenNationsRoles;
        }
    }

    //====================================================================

    function getDeployer() public view returns(address) {
        return _deployer;
    }

    function getCitizenNations(address citizen) public view returns(address[] memory) {
        uint count = IDeployer(_deployer).getNationCount();
        address[] memory citizenNationsTemp = new address[](count);
        address[] memory nations = IDeployer(_deployer).getNations();
        uint citizenNationsCount = 0;
        for (uint i = 0; i < count; i++) {
            address nationAddress = nations[i];
            if (isCitizenNation(citizen, nationAddress)) {
                citizenNationsTemp[citizenNationsCount] = nationAddress;
                citizenNationsCount++;
            }
        }
        if (citizenNationsCount == 0) {
            return new address[](0);
        }
        else {
            address[] memory citizenNations = new address[](citizenNationsCount);
            for (uint i = 0; i < citizenNationsCount; i++) {
                citizenNations[i] = citizenNationsTemp[i];
            }
            return citizenNations;
        }

    }

    function isCitizenNation(address citizen_, address nation_) public view returns(bool) {
        address citizenAlpha = INation(nation_).getCitizenAlpha();
        return ICitizenAlpha1(citizenAlpha).isCitizen(citizen_);
    }
}