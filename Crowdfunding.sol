// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Crowdfunding {
    enum State {
        Active,
        Closed
    }

    struct Contribution {
        address contributor;
        uint256 value;
    }

    struct Project {
        string id;
        string name;
        string description;
        address payable author;
        State state;
        uint256 goal;
        uint256 currentFund;
    }

    Project[] public projects;

    mapping(uint256 => Contribution[]) public contributions;

    //This modifier makes sure that the caller is the owner of the contract.
    modifier onlyOwner(uint256 projectIndex) {
        require(
            msg.sender == projects[projectIndex].author,
            "Only owners execute this function"
        );
        _;
    }

    modifier notTheOwner(uint256 projectIndex) {
        require(
            projects[projectIndex].author != msg.sender,
            "You can't fund your own project"
        );
        _;
    }

    event newProject(string id, string name, string description, uint256 goal);

    event newFund(string id, address sender, uint256 amount);

    event newStatus(string id, State status);

    error sameStatus();

    function createProject(
        string calldata id,
        string calldata name,
        string calldata description,
        uint256 goal,
        uint256 curentFund
    ) public {
        require(goal > 0, "Goal must be greater than 0");
        Project memory project = Project(
            id,
            name,
            description,
            payable(msg.sender),
            State.Active,
            goal,
            curentFund
        );
        projects.push(project);
        emit newProject(id, name, description, goal);
    }

    function changeFundState(State newState, uint256 projectIndex)
        public
        onlyOwner(projectIndex)
    {
        Project memory project = projects[projectIndex];
        if (newState == project.state) {
            revert sameStatus();
        } else {
            project.state = newState;
            emit newStatus(project.id, newState);
        }
    }

    function fundProject(uint256 projectIndex)
        public
        payable
        notTheOwner(projectIndex)
    {
        Project memory project = projects[projectIndex];
        require(msg.value > 0, "You don't have enought funds");
        require(project.state != State.Closed, "Project is not available");

        project.author.transfer(msg.value); // This value will be on GWEI
        project.currentFund += msg.value;

        contributions[projectIndex].push(Contribution(msg.sender, msg.value));

        emit newFund(project.id, msg.sender, msg.value);
    }
}
