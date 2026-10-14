import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime policy is in its life cycle.
    enum OvertimePolicyStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A overtime policy. Its code is unique within a tenant.
    final class OvertimePolicy {
        var code: String
        var title: String
        var limit: Int
        var procedureCode: String
        var rate: Double
        var status: OvertimePolicyStatus

        init(code: String, title: String, limit: Int, procedureCode: String, rate: Double, status: OvertimePolicyStatus) {
            self.code = code
            self.title = title
            self.limit = limit
            self.procedureCode = procedureCode
            self.rate = rate
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

        func canMoveTo(_ next: OvertimePolicyStatus) -> Bool {
            switch status {
            case .`open`:
                return next == OvertimePolicyStatus.archived
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
                return next == OvertimePolicyStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OvertimePolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netVolume() -> Double {
            return (Double(limit) * rate * 100).rounded() / 100
        }

        func copyValue() -> OvertimePolicy {
            return OvertimePolicy(
                code: code,
                title: title,
                limit: limit,
                procedureCode: procedureCode,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a overtime policy in status open.
    static func newOvertimePolicy(_ code: String, title: String) -> OvertimePolicy {
        return OvertimePolicy(
            code: code,
            title: title,
            limit: 0,
            procedureCode: "",
            rate: 0.0,
            status: OvertimePolicyStatus.`open`
        )
    }
}
