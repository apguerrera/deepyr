pragma solidity ^0.4.23;


contract lastWill {
    bytes data;
    modifier auth {
            require(msg.sender == authorised);
            _;
    }
    function addData(bytes _data) public auth {
        data = _data;
    }

}
