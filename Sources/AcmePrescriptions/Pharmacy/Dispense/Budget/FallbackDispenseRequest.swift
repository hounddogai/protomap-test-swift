import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a fallback dispense request is in its life cycle.
    enum FallbackDispenseRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A fallback dispense request as the dispense team keeps it.
    final class FallbackDispenseRequest {
        var code: String
        var title: String
        var attributes: [String: String]
        var version: Int
        var category: String
        var minimum: Double
        var quantity: Int
        var status: FallbackDispenseRequestStatus

        init(code: String, title: String, attributes: [String: String], version: Int, category: String, minimum: Double, quantity: Int, status: FallbackDispenseRequestStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.version = version
            self.category = category
            self.minimum = minimum
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackDispenseRequestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == FallbackDispenseRequestStatus.active || next == FallbackDispenseRequestStatus.suspended
            case .active:
                return next == FallbackDispenseRequestStatus.suspended || next == FallbackDispenseRequestStatus.closed
            case .suspended:
                return next == FallbackDispenseRequestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackDispenseRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback dispense request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveLoad() -> Double {
            return ((Double(quantity) + minimum) * 100).rounded() / 100
        }

        func copyValue() -> FallbackDispenseRequest {
            return FallbackDispenseRequest(
                code: code,
                title: title,
                attributes: attributes,
                version: version,
                category: category,
                minimum: minimum,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a fallback dispense request in status draft.
    static func newFallbackDispenseRequest(_ code: String, title: String) -> FallbackDispenseRequest {
        return FallbackDispenseRequest(
            code: code,
            title: title,
            attributes: [:],
            version: 0,
            category: "",
            minimum: 0.0,
            quantity: 0,
            status: FallbackDispenseRequestStatus.draft
        )
    }
}
