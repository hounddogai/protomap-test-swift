import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall budget is in its life cycle.
    enum RecallBudgetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A recall budget. Its code is unique within a tenant.
    final class RecallBudget {
        var code: String
        var label: String
        var name: String
        var expiresAt: Int
        var floorValue: Double
        var version: Int
        var status: RecallBudgetStatus

        init(code: String, label: String, name: String, expiresAt: Int, floorValue: Double, version: Int, status: RecallBudgetStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.expiresAt = expiresAt
            self.floorValue = floorValue
            self.version = version
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

        func canMoveTo(_ next: RecallBudgetStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RecallBudgetStatus.inReview
            case .inReview:
                return next == RecallBudgetStatus.resolved || next == RecallBudgetStatus.archived
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RecallBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netExposure() -> Double {
            return ((Double(expiresAt) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> RecallBudget {
            return RecallBudget(
                code: code,
                label: label,
                name: name,
                expiresAt: expiresAt,
                floorValue: floorValue,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a recall budget in status open.
    static func newRecallBudget(_ code: String, label: String) -> RecallBudget {
        return RecallBudget(
            code: code,
            label: label,
            name: "",
            expiresAt: 0,
            floorValue: 0.0,
            version: 0,
            status: RecallBudgetStatus.`open`
        )
    }
}
