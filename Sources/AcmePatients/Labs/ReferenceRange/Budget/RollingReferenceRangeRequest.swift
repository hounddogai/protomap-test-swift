import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling reference range request is in its life cycle.
    enum RollingReferenceRangeRequestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A rolling reference range request as the reference range team keeps it.
    final class RollingReferenceRangeRequest {
        var code: String
        var label: String
        var description: String
        var acuity: Int
        var active: Bool
        var status: RollingReferenceRangeRequestStatus

        init(code: String, label: String, description: String, acuity: Int, active: Bool, status: RollingReferenceRangeRequestStatus) {
            self.code = code
            self.label = label
            self.description = description
            self.acuity = acuity
            self.active = active
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

        func canMoveTo(_ next: RollingReferenceRangeRequestStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
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

        func moveTo(_ next: RollingReferenceRangeRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling reference range request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("rolling reference range request") \(code)"
        }

        func measuredValue() -> Double {
            return Double(acuity)
        }

        func copyValue() -> RollingReferenceRangeRequest {
            return RollingReferenceRangeRequest(
                code: code,
                label: label,
                description: description,
                acuity: acuity,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling reference range request in status open.
    static func newRollingReferenceRangeRequest(_ code: String, label: String) -> RollingReferenceRangeRequest {
        return RollingReferenceRangeRequest(
            code: code,
            label: label,
            description: "",
            acuity: 0,
            active: false,
            status: RollingReferenceRangeRequestStatus.`open`
        )
    }
}
