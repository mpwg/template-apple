# Code Style Guide

This document outlines the coding standards and style guidelines for iOS/macOS development in this project. These guidelines ensure consistency, readability, and maintainability across the codebase.

## Table of Contents

- [General Principles](#general-principles)
- [Swift Style Guidelines](#swift-style-guidelines)
- [Project Organization](#project-organization)
- [Naming Conventions](#naming-conventions)
- [Code Structure](#code-structure)
- [Documentation](#documentation)
- [SwiftLint Configuration](#swiftlint-configuration)
- [SwiftFormat Configuration](#swiftformat-configuration)
- [Best Practices](#best-practices)
- [Examples](#examples)

## General Principles

### Code Should Be

1. **Readable**: Code is read more often than written
2. **Consistent**: Follow established patterns throughout the project
3. **Simple**: Prefer simple solutions over complex ones
4. **Safe**: Use Swift's type safety features
5. **Performant**: Consider performance implications
6. **Testable**: Write code that can be easily tested

### Team Standards

- **Line Length**: Maximum 120 characters (soft limit), 160 characters (hard limit)
- **Indentation**: 4 spaces (no tabs)
- **File Encoding**: UTF-8
- **Line Endings**: LF (Unix-style)
- **Trailing Whitespace**: Remove all trailing whitespace

## Swift Style Guidelines

### Basic Formatting

**Indentation and Spacing:**
```swift
// ✅ Good
func processUserData(
    name: String,
    email: String,
    preferences: UserPreferences
) -> ProcessedUser {
    let processedUser = ProcessedUser()
    // Implementation
    return processedUser
}

// ❌ Bad
func processUserData(name: String, email: String, preferences: UserPreferences) -> ProcessedUser {
let processedUser = ProcessedUser()
    // Implementation
return processedUser
}
```

**Braces:**
```swift
// ✅ Good
if condition {
    doSomething()
} else {
    doSomethingElse()
}

// ❌ Bad
if condition
{
    doSomething()
}
else {
    doSomethingElse()
}
```

### Type Declarations

**Classes and Structures:**
```swift
// ✅ Good
class UserManager {
    // MARK: - Properties
    private let apiClient: APIClient
    private var cachedUsers: [User] = []

    // MARK: - Initialization
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Public Methods
    func fetchUsers() async throws -> [User] {
        // Implementation
    }

    // MARK: - Private Methods
    private func cacheUsers(_ users: [User]) {
        cachedUsers = users
    }
}
```

**Protocols:**
```swift
// ✅ Good
protocol UserServiceProtocol {
    func fetchUser(id: String) async throws -> User
    func updateUser(_ user: User) async throws
    func deleteUser(id: String) async throws
}

// Use protocol composition when appropriate
typealias UserManaging = UserServiceProtocol & Sendable
```

### Properties and Variables

**Property Declarations:**
```swift
// ✅ Good - Clear property organization
class ViewController: UIViewController {
    // MARK: - IBOutlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var submitButton: UIButton!

    // MARK: - Properties
    private let viewModel: ViewModelProtocol
    private var dataSource: [Item] = []

    // MARK: - Computed Properties
    private var isFormValid: Bool {
        return !textField.text.isEmpty
    }
}
```

**Lazy Properties:**
```swift
// ✅ Good
private lazy var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

// ✅ Good - Simple lazy property
private lazy var userDefaults = UserDefaults.standard
```

### Functions and Methods

**Function Declarations:**
```swift
// ✅ Good - Clear parameter naming
func updateUser(
    withID id: String,
    name: String,
    email: String,
    completion: @escaping (Result<User, Error>) -> Void
) {
    // Implementation
}

// ✅ Good - Async/await version
func updateUser(withID id: String, name: String, email: String) async throws -> User {
    // Implementation
}
```

**Method Organization:**
```swift
// ✅ Good - Grouped by functionality
extension UserViewController {
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    // MARK: - Setup
    private func setupUI() {
        // UI setup
    }

    private func bindViewModel() {
        // ViewModel binding
    }

    // MARK: - Actions
    @IBAction private func submitButtonTapped(_ sender: UIButton) {
        // Action handling
    }
}
```

### Closures and Callbacks

**Closure Syntax:**
```swift
// ✅ Good - Trailing closure syntax
users.map { user in
    return user.displayName
}

// ✅ Good - Shorthand when appropriate
users.map(\.displayName)

// ✅ Good - Multiple line closures
let sortedUsers = users.sorted { lhs, rhs in
    lhs.createdAt > rhs.createdAt
}
```

**Escaping Closures:**
```swift
// ✅ Good - Clear completion handler
func fetchData(completion: @escaping (Result<Data, Error>) -> Void) {
    // Implementation
}

// ✅ Good - Modern async/await preferred
func fetchData() async throws -> Data {
    // Implementation
}
```

### Error Handling

**Error Types:**
```swift
// ✅ Good - Descriptive error types
enum NetworkError: LocalizedError {
    case invalidURL
    case noInternetConnection
    case serverError(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL provided"
        case .noInternetConnection:
            return "No internet connection available"
        case .serverError(let code):
            return "Server error with code: \(code)"
        case .decodingFailed:
            return "Failed to decode response"
        }
    }
}
```

**Error Handling Patterns:**
```swift
// ✅ Good - Handle errors appropriately
do {
    let user = try await userService.fetchUser(id: userID)
    updateUI(with: user)
} catch let networkError as NetworkError {
    handleNetworkError(networkError)
} catch {
    handleUnexpectedError(error)
}

// ✅ Good - Guard for early returns
guard let url = URL(string: urlString) else {
    throw NetworkError.invalidURL
}
```

## Project Organization

### File Structure

**Recommended Project Structure:**
```
ProjectName/
├── Sources/
│   ├── App/
│   │   ├── AppDelegate.swift
│   │   ├── SceneDelegate.swift
│   │   └── Info.plist
│   ├── Features/
│   │   ├── Authentication/
│   │   │   ├── Models/
│   │   │   ├── Views/
│   │   │   ├── ViewModels/
│   │   │   └── Services/
│   │   └── UserProfile/
│   │       ├── Models/
│   │       ├── Views/
│   │       ├── ViewModels/
│   │       └── Services/
│   ├── Core/
│   │   ├── Networking/
│   │   ├── Storage/
│   │   ├── Extensions/
│   │   └── Utilities/
│   └── Resources/
│       ├── Assets.xcassets
│       ├── Localizable.strings
│       └── Fonts/
├── Tests/
│   ├── UnitTests/
│   ├── IntegrationTests/
│   └── UITests/
└── Supporting Files/
    ├── Package.swift
    ├── .swiftlint.yml
    └── .swiftformat
```

### File Naming

**Swift Files:**
- Use PascalCase: `UserViewController.swift`
- Be descriptive: `NetworkRequestManager.swift`
- Include type suffix: `UserService.swift`, `LoginViewModel.swift`

**Resource Files:**
- Use kebab-case: `user-profile-icon.png`
- Be descriptive: `authentication-background.pdf`
- Include size when relevant: `app-icon-60@2x.png`

### MARK Comments

**Use MARK comments to organize code:**
```swift
class UserViewController: UIViewController {
    // MARK: - Properties
    private let viewModel: UserViewModel

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Setup
    private func setupUI() {
        // Implementation
    }

    // MARK: - Actions
    @IBAction private func saveButtonTapped(_ sender: UIButton) {
        // Implementation
    }
}

// MARK: - UITableViewDataSource
extension UserViewController: UITableViewDataSource {
    // Implementation
}

// MARK: - Private Extensions
private extension UserViewController {
    func helperMethod() {
        // Implementation
    }
}
```

## Naming Conventions

### Variables and Properties

**General Rules:**
```swift
// ✅ Good - Clear and descriptive
let userAccountManager = UserAccountManager()
let isUserLoggedIn = false
let maximumRetryCount = 3

// ❌ Bad - Abbreviated or unclear
let uam = UserAccountManager()
let usrLoggedIn = false
let maxRetries = 3
```

**Boolean Properties:**
```swift
// ✅ Good - Use is/has/can/should prefixes
var isLoading = false
var hasValidCredentials = true
var canEditProfile = false
var shouldShowOnboarding = true

// ❌ Bad
var loading = false
var validCredentials = true
var editProfile = false
var showOnboarding = true
```

### Functions and Methods

**Function Names:**
```swift
// ✅ Good - Action verbs with clear intent
func authenticateUser(with credentials: Credentials) async throws -> User
func validateEmail(_ email: String) -> Bool
func presentErrorAlert(for error: Error)

// ❌ Bad - Unclear or abbreviated
func auth(creds: Credentials) async throws -> User
func checkEmail(_ email: String) -> Bool
func showError(_ error: Error)
```

**Delegate Methods:**
```swift
// ✅ Good - Follow delegate naming patterns
protocol UserManagerDelegate: AnyObject {
    func userManager(_ manager: UserManager, didUpdateUser user: User)
    func userManager(_ manager: UserManager, didFailWithError error: Error)
    func userManagerDidCompleteSync(_ manager: UserManager)
}
```

### Types and Protocols

**Protocol Names:**
```swift
// ✅ Good - Use -able, -ing, or descriptive nouns
protocol Drawable {
    func draw()
}

protocol UserManaging {
    func fetchUser(id: String) async throws -> User
}

protocol NetworkRequestDelegate: AnyObject {
    func requestDidComplete(_ request: NetworkRequest)
}
```

**Enum Names:**
```swift
// ✅ Good - Descriptive and grouped
enum NetworkError {
    case invalidURL
    case networkUnavailable
    case serverError(code: Int)
}

enum UserRole {
    case admin
    case moderator
    case regularUser
}
```

## Code Structure

### Access Control

**Use appropriate access levels:**
```swift
// ✅ Good - Restrictive by default
public class APIClient {
    private let session: URLSession
    private let baseURL: URL

    public init(baseURL: URL) {
        self.baseURL = baseURL
        self.session = URLSession.shared
    }

    public func fetchData<T: Codable>(
        from endpoint: String,
        type: T.Type
    ) async throws -> T {
        // Implementation
    }

    private func buildRequest(for endpoint: String) -> URLRequest {
        // Implementation
    }
}
```

### Extensions

**Organize code with extensions:**
```swift
// MARK: - Core Implementation
class UserViewController: UIViewController {
    // Core properties and methods
}

// MARK: - UITableViewDataSource
extension UserViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
}

// MARK: - UITableViewDelegate
extension UserViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Handle selection
    }
}

// MARK: - Private Helpers
private extension UserViewController {
    func setupTableView() {
        // Setup implementation
    }
}
```

## Documentation

### Code Comments

**Use comments effectively:**
```swift
// ✅ Good - Explain complex logic
/// Calculates the user's credit score based on payment history and account age
/// - Parameters:
///   - paymentHistory: Array of payment records
///   - accountAge: Age of account in months
/// - Returns: Credit score between 300-850
func calculateCreditScore(
    paymentHistory: [PaymentRecord],
    accountAge: Int
) -> Int {
    // Complex algorithm implementation
    // Weight recent payments more heavily
    let recentPayments = paymentHistory.suffix(12)
    // ... implementation
}

// ✅ Good - Explain workarounds
// TODO: Remove this workaround when iOS 17 is minimum deployment target
if #available(iOS 17.0, *) {
    useNewAPI()
} else {
    // Fallback implementation for older iOS versions
    useLegacyAPI()
}
```

**Documentation Comments:**
```swift
/// Manages user authentication and session state
///
/// This class handles all authentication-related operations including login,
/// logout, token refresh, and session validation. It uses keychain storage
/// for secure credential persistence.
///
/// Example usage:
/// ```swift
/// let authManager = AuthenticationManager()
/// let user = try await authManager.login(email: "user@example.com", password: "password")
/// ```
///
/// - Important: This class is thread-safe and can be used from any queue
/// - Note: Requires network connectivity for most operations
class AuthenticationManager {
    // Implementation
}
```

### TODO and FIXME

**Use structured TODO comments:**
```swift
// TODO: [TASK-123] Implement biometric authentication
// TODO: Refactor to use async/await (target: v2.1)
// FIXME: Handle edge case when user has no internet connection
// HACK: Temporary workaround for API limitation - remove when fixed
```

## SwiftLint Configuration

Our SwiftLint configuration enforces these standards automatically. Key rules include:

**Enabled Rules:**
- `line_length` (120 warning, 160 error)
- `function_body_length` (60 warning, 100 error)
- `cyclomatic_complexity` (15 warning, 25 error)
- `nesting` (type: 3/5, function: 4/6)
- `force_unwrapping` (opt-in rule)
- `implicitly_unwrapped_optional` (opt-in rule)

**Custom Rules:**
- No print statements in production code
- Proper TODO format enforcement
- Operator spacing validation

## SwiftFormat Configuration

SwiftFormat automatically handles:

- 4-space indentation
- 120 character line width
- Consistent brace placement
- Import organization
- Trailing comma removal
- Redundant code removal

## Best Practices

### Performance

**Memory Management:**
```swift
// ✅ Good - Use weak references to avoid retain cycles
class UserViewModel {
    weak var delegate: UserViewModelDelegate?

    private func notifyDelegate() {
        delegate?.viewModelDidUpdate(self)
    }
}

// ✅ Good - Use unowned for guaranteed lifetime
class UserView: UIView {
    unowned let viewModel: UserViewModel

    init(viewModel: UserViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
    }
}
```

**Lazy Initialization:**
```swift
// ✅ Good - Expensive operations
private lazy var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

// ✅ Good - UI components
private lazy var stackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.spacing = 16
    return stackView
}()
```

### Safety

**Optional Handling:**
```swift
// ✅ Good - Safe optional unwrapping
guard let user = currentUser else {
    logger.warning("Attempted to update profile without logged-in user")
    return
}

// ✅ Good - Nil coalescing for defaults
let displayName = user.displayName ?? "Unknown User"

// ✅ Good - Optional chaining
user.profile?.updateLastSeen(Date())
```

**Type Safety:**
```swift
// ✅ Good - Use enums for constants
enum APIEndpoint {
    static let baseURL = "https://api.example.com"
    static let users = "/users"
    static let profile = "/profile"
}

// ✅ Good - Strongly typed identifiers
struct UserID {
    let value: String
}

struct PostID {
    let value: String
}
```

### Testing

**Testable Code:**
```swift
// ✅ Good - Dependency injection
class UserService {
    private let apiClient: APIClientProtocol
    private let storage: StorageProtocol

    init(apiClient: APIClientProtocol, storage: StorageProtocol) {
        self.apiClient = apiClient
        self.storage = storage
    }
}

// ✅ Good - Protocol-based dependencies
protocol APIClientProtocol {
    func fetchUser(id: String) async throws -> User
}
```

## Examples

### Complete Class Example

```swift
import Foundation
import Combine

/// Manages user profile data and operations
///
/// This service handles all user profile-related operations including
/// fetching, updating, and caching profile information.
final class UserProfileService {

    // MARK: - Properties

    private let apiClient: APIClientProtocol
    private let storage: StorageProtocol
    private let logger: LoggerProtocol

    @Published private(set) var currentProfile: UserProfile?
    @Published private(set) var isLoading = false

    // MARK: - Initialization

    init(
        apiClient: APIClientProtocol,
        storage: StorageProtocol,
        logger: LoggerProtocol
    ) {
        self.apiClient = apiClient
        self.storage = storage
        self.logger = logger
    }

    // MARK: - Public Methods

    /// Fetches the user profile from the server
    /// - Parameter userID: The ID of the user to fetch
    /// - Returns: The user's profile
    /// - Throws: NetworkError if the request fails
    func fetchProfile(for userID: UserID) async throws -> UserProfile {
        logger.info("Fetching profile for user: \(userID.value)")

        isLoading = true
        defer { isLoading = false }

        do {
            let profile = try await apiClient.fetchUserProfile(userID: userID.value)
            await cacheProfile(profile)

            DispatchQueue.main.async {
                self.currentProfile = profile
            }

            logger.info("Successfully fetched profile for user: \(userID.value)")
            return profile

        } catch {
            logger.error("Failed to fetch profile: \(error)")
            throw NetworkError.fetchFailed(underlying: error)
        }
    }

    /// Updates the user profile on the server
    /// - Parameter profile: The updated profile data
    /// - Returns: The updated profile from the server
    /// - Throws: NetworkError if the update fails
    func updateProfile(_ profile: UserProfile) async throws -> UserProfile {
        logger.info("Updating profile for user: \(profile.id)")

        isLoading = true
        defer { isLoading = false }

        do {
            let updatedProfile = try await apiClient.updateUserProfile(profile)
            await cacheProfile(updatedProfile)

            DispatchQueue.main.async {
                self.currentProfile = updatedProfile
            }

            logger.info("Successfully updated profile for user: \(profile.id)")
            return updatedProfile

        } catch {
            logger.error("Failed to update profile: \(error)")
            throw NetworkError.updateFailed(underlying: error)
        }
    }

    // MARK: - Private Methods

    private func cacheProfile(_ profile: UserProfile) async {
        do {
            try await storage.save(profile, forKey: "user_profile_\(profile.id)")
            logger.debug("Cached profile for user: \(profile.id)")
        } catch {
            logger.warning("Failed to cache profile: \(error)")
        }
    }

    private func loadCachedProfile(for userID: UserID) async -> UserProfile? {
        do {
            return try await storage.load(
                UserProfile.self,
                forKey: "user_profile_\(userID.value)"
            )
        } catch {
            logger.debug("No cached profile found for user: \(userID.value)")
            return nil
        }
    }
}

// MARK: - Error Types

enum NetworkError: LocalizedError {
    case fetchFailed(underlying: Error)
    case updateFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update data: \(error.localizedDescription)"
        }
    }
}
```

---

## Enforcement

This style guide is enforced through:

1. **SwiftLint** - Automated style checking
2. **SwiftFormat** - Automated code formatting
3. **Git Hooks** - Pre-commit validation
4. **Code Reviews** - Human validation
5. **CI/CD Pipeline** - Continuous validation

## Resources

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [SwiftLint Rules](https://realm.github.io/SwiftLint/rule-directory.html)
- [SwiftFormat Configuration](https://github.com/nicklockwood/SwiftFormat#configuration)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

---

**Last Updated**: $(date)
**Style Guide Version**: 1.0.0
**Review Schedule**: Quarterly

For questions or suggestions about the code style guide, please create a GitHub issue or discuss with the development team.