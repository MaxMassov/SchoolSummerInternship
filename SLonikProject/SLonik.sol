// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SLonik is ERC20, Ownable {

    constructor() ERC20("SLonik", "SLN") {}

    function mint(uint _amount) public onlyOwner {
        totalSLonikAmount = _amount;
        _mint(owner(), totalSLonikAmount);
    }

    struct Student {
        bool isBlocked;
        uint inSolving;
    }

    struct Task {
        string condition;
        string plan;
        uint commission;
        uint penalty;
        uint award;
        bool isAutoChecked;
        bool isAvailable;
    }

    struct Solution {
        int answer;
        int accuracy;
        string picture;
    }

    uint public totalSLonikAmount = 200;
    uint public amountOfTasks = 0;
    uint newTaskNum = 0;
    uint public maxTasksInSolving = 5;
    uint public lowestCommission = 100000000000000000000000000000000000000000000000000000000000000000000000000000;
    uint public costOfEvaluation = 21 * 1000000;

    bool isAllBlocked = false;

    mapping (address => Student) students;
    mapping (uint => Task) tasks;
    mapping (uint => Solution) solutions;
    mapping (address => mapping (uint => uint)) resolvedTasks;
    
    // utils

    function random(uint number) internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % number;
    }

    function min(uint a, uint b) internal pure returns (uint) {
        if (a > b) return b;
        return a;
    }

    function checkExistence(uint _taskId) internal view returns (bool) {

        require(_taskId < newTaskNum, "The task does not exist.");
        require(bytes(tasks[_taskId].condition).length != 0 || 
            bytes(tasks[_taskId].plan).length != 0, 
            "The task does not exist.");
        return true;
    }

    // Teacher
    // for tokens

    function changeTotalAmountBy(uint _supplement, bool _decrease) public onlyOwner {
        if (_decrease) {
            require(totalSLonikAmount - _supplement > 0, "The total amount of SLoniks must be greater than 0.");
            totalSLonikAmount -= _supplement;
        } else {
            totalSLonikAmount += _supplement;
        }
        _mint(owner(), totalSLonikAmount);
    }

    // for students

    function changeMaxTasksInSolving(uint _newValue) public onlyOwner {
        maxTasksInSolving = _newValue;
    }

    function blockAllStudents() public onlyOwner {
        isAllBlocked = true;
    }

    function unblockAllStudents() public onlyOwner {
        isAllBlocked = false;
    }

    function blockStudent(address _student) public onlyOwner {
        students[_student].isBlocked = true;
    }

    function unblockStudent(address _student) public onlyOwner {
        students[_student].isBlocked = false;
    }

    function changeCostOfEvaluation(uint _costOfEvaluation) public onlyOwner {
        require(_costOfEvaluation > 0, "The cost of esvaluation must be greater than 0.");
        costOfEvaluation = _costOfEvaluation;
    }

    // for tasks

    function createTask(string calldata _taskUrl, uint _commission, uint _penalty,
                        uint _award, bool _isAutoChecked, bool _isAvailable,
                        int _answer, int _accuracy, string calldata _picture) 
                                        public onlyOwner returns (uint) {
        
        lowestCommission = min(lowestCommission, _commission);

        // ToDo: add task
        tasks[newTaskNum] = Task(_taskUrl, "", _commission, _penalty,
                                    _award, _isAutoChecked, _isAvailable);
        // ToDo: add solution
        solutions[newTaskNum] = Solution(_answer, _accuracy, _picture);
        //

        amountOfTasks++;
        newTaskNum++;
        return newTaskNum - 1;
    }

    function deleteTask(uint _taskId) public onlyOwner {

        checkExistence(_taskId);
        
        amountOfTasks--;
        
        delete tasks[_taskId];
        delete solutions[_taskId];
    }

    function taskInfo(uint _taskId) public onlyOwner view returns (Task memory, Solution memory) {

        checkExistence(_taskId);

        return (tasks[_taskId], solutions[_taskId]);
    }

    function updateTask(uint _taskId, 
                        string calldata _taskUrl, uint _commission, uint _penalty,
                        uint _award, bool _isAutoChecked, bool _isAvailable) public onlyOwner {

        checkExistence(_taskId);

        lowestCommission = min(lowestCommission, _commission);

        // ToDo: update task
        tasks[newTaskNum] = Task(_taskUrl, "", _commission, _penalty,
                                    _award, _isAutoChecked, _isAvailable);
    }

    function updateSolution(uint _taskId, 
                        int _answer, int _accuracy, string calldata _picture) public onlyOwner {

        checkExistence(_taskId);

        // ToDo: update solution
        solutions[newTaskNum] = Solution(_answer, _accuracy, _picture);
        //        
    }

    // Student

    function getTask() public payable returns (Task memory) {

        require(amountOfTasks > 0, "Your teacher has not added any tasks yet.");
        require(!isAllBlocked, 
            "Your teacher has blocked the possibility of submitting and geting tasks for all students.");
        require(!students[msg.sender].isBlocked, 
            "Your teacher has blocked the possibility of submitting and geting tasks for you.");
        require(students[msg.sender].inSolving < maxTasksInSolving, 
            "Your teacher has limited the number of tasks to be solved at the same time.");
        
        uint taskId = random(newTaskNum);
        for (uint i = 0; i <= newTaskNum; i++) {
            if (resolvedTasks[msg.sender][taskId] != 0 || 
                    !tasks[taskId].isAvailable || 
                    msg.value < tasks[taskId].commission) {
                taskId = (taskId + 1) % newTaskNum;
            }     
        }
        require(resolvedTasks[msg.sender][taskId] == 0, 
            "You have gotten all the tasks or your value is not enough to pay the commission for the remaining tasks.");
        uint overpayment = msg.value - tasks[taskId].commission;
        require(msg.value >= tasks[taskId].commission, 
            "Your value is not enough to pay the commission for the remaining tasks.");
        payable(msg.sender).transfer(overpayment);
        students[msg.sender].inSolving++;
        resolvedTasks[msg.sender][taskId] = 1;
        return tasks[taskId];
    }

    function submitTask(uint _taskId, int answer, string calldata solution) public payable {

        checkExistence(_taskId);
        require(!isAllBlocked, 
            "Your teacher has blocked the possibility of submitting and geting tasks for all students.");
        require(!students[msg.sender].isBlocked, 
            "Your teacher has blocked the possibility of submitting and geting tasks for you.");
        require(resolvedTasks[msg.sender][_taskId] == 1, 
            "You have already solved this task or have never gotten it.");
        
        uint overpayment = 0;
        if (msg.value >= tasks[_taskId].penalty) {
            overpayment = msg.value - tasks[_taskId].commission;
        }
        require(msg.value >= tasks[_taskId].penalty, 
            "Your value is not enough to pay the penalty for completing this task in case of a wrong solution.");
        payable(msg.sender).transfer(overpayment);

        // ToDo: checking the solution
        bool approved = false;
        if (tasks[_taskId].isAutoChecked) {
            approved = ((solutions[_taskId].answer -  answer) > -solutions[_taskId].accuracy &&
                (solutions[_taskId].answer -  answer) < solutions[_taskId].accuracy);
        }
        else {}
        //
        
        require(approved, "The solution is wrong(");

        students[msg.sender].inSolving--;
        resolvedTasks[msg.sender][_taskId] = 2;
        payable(msg.sender).transfer(tasks[_taskId].penalty + tasks[_taskId].award);
    }

    function getFive() public payable {

        require(msg.value == costOfEvaluation, "You have attached the wrong cost.");
        
        // ToDo: return 5
    }

}