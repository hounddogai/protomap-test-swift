import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert rollup is in its life cycle.
    enum AlertRollupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A alert rollup. Its code is unique within a tenant.
    final class AlertRollup {
        var code: String
        var title: String
        var description: String
        var approved: Bool
        var source: String
        var amount: Double
        var status: AlertRollupStatus

        init(code: String, title: String, description: String, approved: Bool, source: String, amount: Double, status: AlertRollupStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.approved = approved
            self.source = source
            self.amount = amount
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

        func canMoveTo(_ next: AlertRollupStatus) -> Bool {
            switch status {
            case .`open`:
                return next == AlertRollupStatus.inReview || next == AlertRollupStatus.archived
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == AlertRollupStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AlertRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("alert rollup") \(code)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> AlertRollup {
            return AlertRollup(
                code: code,
                title: title,
                description: description,
                approved: approved,
                source: source,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a alert rollup in status open.
    static func newAlertRollup(_ code: String, title: String) -> AlertRollup {
        return AlertRollup(
            code: code,
            title: title,
            description: "",
            approved: false,
            source: "",
            amount: 0.0,
            status: AlertRollupStatus.`open`
        )
    }
}
