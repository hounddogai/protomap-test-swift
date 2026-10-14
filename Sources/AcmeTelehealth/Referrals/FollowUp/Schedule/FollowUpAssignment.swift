import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up assignment is in its life cycle.
    enum FollowUpAssignmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A follow up assignment as the follow up team keeps it.
    final class FollowUpAssignment {
        var code: String
        var title: String
        var bed: String
        var acuity: Int
        var ratio: Double
        var status: FollowUpAssignmentStatus

        init(code: String, title: String, bed: String, acuity: Int, ratio: Double, status: FollowUpAssignmentStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.acuity = acuity
            self.ratio = ratio
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FollowUpAssignmentStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: FollowUpAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netExposure() -> Double {
            return (ratio * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpAssignment {
            return FollowUpAssignment(
                code: code,
                title: title,
                bed: bed,
                acuity: acuity,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a follow up assignment in status created.
    static func newFollowUpAssignment(_ code: String, title: String) -> FollowUpAssignment {
        return FollowUpAssignment(
            code: code,
            title: title,
            bed: "",
            acuity: 0,
            ratio: 0.0,
            status: FollowUpAssignmentStatus.created
        )
    }
}
