import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge baseline is in its life cycle.
    enum ChargeBaselineStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A charge baseline as the charge team keeps it.
    final class ChargeBaseline {
        var code: String
        var name: String
        var version: Int
        var cost: Double
        var allergy: String
        var attempts: Int
        var title: String
        var label: String
        var status: ChargeBaselineStatus

        init(code: String, name: String, version: Int, cost: Double, allergy: String, attempts: Int, title: String, label: String, status: ChargeBaselineStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.cost = cost
            self.allergy = allergy
            self.attempts = attempts
            self.title = title
            self.label = label
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ChargeBaselineStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ChargeBaselineStatus.archived
            case .inReview:
                return next == ChargeBaselineStatus.archived
            case .resolved:
                return next == ChargeBaselineStatus.archived
            case .reopened:
                return next == ChargeBaselineStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ChargeBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func projectedLoad() -> Double {
            return ((Double(attempts) - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> ChargeBaseline {
            return ChargeBaseline(
                code: code,
                name: name,
                version: version,
                cost: cost,
                allergy: allergy,
                attempts: attempts,
                title: title,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a charge baseline in status open.
    static func newChargeBaseline(_ code: String, name: String) -> ChargeBaseline {
        return ChargeBaseline(
            code: code,
            name: name,
            version: 0,
            cost: 0.0,
            allergy: "",
            attempts: 0,
            title: "",
            label: "",
            status: ChargeBaselineStatus.`open`
        )
    }
}
