
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Import the SponsorshipToken contract
import "./blogToken.sol";  

contract MemoVerse is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct BlogPost {
        uint256 id;
        address author;
        string title;
        string content;
        string richText;
        uint256 timestamp;
        uint256 sponsoredAmount;
    }

    struct Comment {
        address commenter;
        string content;
        uint256 timestamp;
    }

    struct UserProfile {
        string name;
        string photoAlbumHash;
        uint256[] blogPostIds;
    }

    BlogPost[] public blogPosts;
    mapping(address => uint256[]) private userPosts;
    mapping(address => UserProfile) private userProfiles;
    mapping(uint256 => Comment[]) public postComments;
    mapping(address => bool) private isAdmin;
    mapping(uint256 => mapping(address => uint256)) private postAppreciations;

    string public tokenSymbol;

    SponsorshipToken public sponsorshipToken;  // Declare an instance of SponsorshipToken contract

    event BlogPostPublished(uint256 indexed postId, address indexed author);
    event BlogPostUpdated(uint256 indexed postId, address indexed author);
    event CommentAdded(uint256 indexed postId, address indexed commenter, string content);
    event PostLiked(uint256 indexed postId, address indexed liker);
    event UserProfileUpdated(address indexed user, string name, string photoAlbumHash);
    event AdminChanged(address indexed admin, bool status);
    event PostSponsored(uint256 indexed postId, address indexed sponsor, uint256 amount);
    event SponsorshipWithdrawn(uint256 indexed postId, address indexed sponsor, uint256 amount);

    modifier onlyPostAuthor(uint256 postId) {
        require(postId < blogPosts.length, "Invalid post ID");
        require(blogPosts[postId].author == msg.sender, "You can only edit your own posts");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender] || msg.sender == owner(), "Only admin can call this");
        _;
    }

    constructor(SponsorshipToken _tokenContractAddress, string memory _tokenSymbol) {
        sponsorshipToken = _tokenContractAddress;
        tokenSymbol = _tokenSymbol;
    }

    function createBlogPost(string memory title, string memory content, string memory richText) external {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(content).length > 0, "Content cannot be empty");

        uint256 postId = blogPosts.length;
        blogPosts.push(BlogPost(postId, msg.sender, title, content, richText, block.timestamp, 0));
        userPosts[msg.sender].push(postId);

        emit BlogPostPublished(postId, msg.sender);
    }

    function editBlogPost(uint256 postId, string memory title, string memory content, string memory richText)
        external
        onlyPostAuthor(postId)
    {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(content).length > 0, "Content cannot be empty");

        BlogPost storage post = blogPosts[postId];
        post.title = title;
        post.content = content;
        post.richText = richText;

        emit BlogPostUpdated(postId, msg.sender);
    }

    function addComment(uint256 postId, string memory content) external {
        require(postId < blogPosts.length, "Invalid post ID");
        require(bytes(content).length > 0, "Comment content cannot be empty");
        require(bytes(content).length <= 200, "Comment is too long");

        Comment memory newComment = Comment(msg.sender, content, block.timestamp);
        postComments[postId].push(newComment);

        emit CommentAdded(postId, msg.sender, content);
    }

    function createOrUpdateUserProfile(string memory name, string memory photoAlbumHash) external {
        require(bytes(name).length > 0, "Name cannot be empty");

        UserProfile storage userProfile = userProfiles[msg.sender];
        userProfile.name = name;
        userProfile.photoAlbumHash = photoAlbumHash;

        emit UserProfileUpdated(msg.sender, name, photoAlbumHash);
    }

    function getUserProfile(address user) external view returns (string memory name, string memory photoAlbumHash, uint256[] memory blogPostIds) {
        UserProfile memory userProfile = userProfiles[user];
        return (userProfile.name, userProfile.photoAlbumHash, userProfile.blogPostIds);
    }

    function getBlogPost(uint256 postId) external view returns (BlogPost memory) {
        require(postId < blogPosts.length, "Invalid post ID");

        BlogPost memory post = blogPosts[postId];
        post.sponsoredAmount = sponsorshipToken.balanceOf(address(this));

        return post;
    }

    function getUserPosts(address user) external view returns (uint256[] memory) {
        return userPosts[user];
    }

    function getNumberOfPosts() external view returns (uint256) {
        return blogPosts.length;
    }

    function setAdminStatus(address user, bool status) external onlyOwner {
        require(user != address(0), "Invalid user address");
        isAdmin[user] = status;

        emit AdminChanged(user, status);
    }

    function sponsorPost(uint256 postId, uint256 amount) external {
        require(postId < blogPosts.length, "Invalid post ID");
        require(amount > 0, "Amount must be greater than 0");

        require(sponsorshipToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        // Deduct the sponsored amount from the user's wallet
        BlogPost storage post = blogPosts[postId];
        post.sponsoredAmount = post.sponsoredAmount.add(amount);

        emit PostSponsored(postId, msg.sender, amount);
    }

    function withdrawSponsorship(uint256 postId) external nonReentrant {
        require(postId < blogPosts.length, "Invalid post ID");

        BlogPost storage post = blogPosts[postId];
        uint256 sponsoredAmount = post.sponsoredAmount;
        require(sponsoredAmount > 0, "No sponsorship found for the post");

        // Transfer the sponsored amount back to the sponsor
        require(sponsorshipToken.transfer(msg.sender, sponsoredAmount), "Token transfer failed");

        // Reset the post's sponsored amount
        post.sponsoredAmount = 0;

        emit SponsorshipWithdrawn(postId, msg.sender, sponsoredAmount);
    }

    // New function to appreciate a post using SponsorshipToken
    // New function to appreciate a post using SponsorshipToken
    function appreciatePostWithTokens(uint256 postId, uint256 amount) external payable {
        require(postId < blogPosts.length, "Invalid post ID");
        require(amount > 0, "Amount must be greater than 0");

        BlogPost storage post = blogPosts[postId];
        require(sponsorshipToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        // Deduct the appreciated amount from the user's wallet
        // and add the amount to the post's sponsored amount
        post.sponsoredAmount = post.sponsoredAmount.add(amount);

        // Track individual appreciation amounts per post and user
        postAppreciations[postId][msg.sender] = postAppreciations[postId][msg.sender].add(amount);

        emit PostSponsored(postId, msg.sender, amount);
    }


    // Feature: Pay Creators Monthly Based on Appreciated Amounts
    function payoutCreators(uint256[] calldata postIds) external onlyAdmin {
        for (uint256 i = 0; i < postIds.length; i++) {
            uint256 postId = postIds[i];
            require(postId < blogPosts.length, "Invalid post ID");

            BlogPost storage post = blogPosts[postId];
            uint256 appreciationAmount = postAppreciations[postId][post.author];

            // Pay out creators based on their appreciation amount
            if (appreciationAmount > 0) {
                require(sponsorshipToken.transfer(post.author, appreciationAmount), "Token transfer failed");
                postAppreciations[postId][post.author] = 0; // Reset appreciation amount
            }
        }
    }
}
