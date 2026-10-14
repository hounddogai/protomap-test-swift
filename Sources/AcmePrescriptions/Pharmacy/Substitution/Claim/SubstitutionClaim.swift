import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution claim is in its life cycle.
    enum SubstitutionClaimStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One substitution claim, with what the planners need to act on it.
    final class SubstitutionClaim {
        var code: String
        var label: String
        var visible: Bool
        var discount: Double
        var active: Bool
        var approved: Bool
        var title: String
        var status: SubstitutionClaimStatus

        init(code: String, label: String, visible: Bool, discount: Double, active: Bool, approved: Bool, title: String, status: SubstitutionClaimStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.discount = discount
            self.active = active
            self.approved = approved
            self.title = title
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SubstitutionClaimStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == SubstitutionClaimStatus.completed
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: SubstitutionClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return discount
        }

        func copyValue() -> SubstitutionClaim {
            return SubstitutionClaim(
                code: code,
                label: label,
                visible: visible,
                discount: discount,
                active: active,
                approved: approved,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a substitution claim in status planned.
    static func newSubstitutionClaim(_ code: String, label: String) -> SubstitutionClaim {
        return SubstitutionClaim(
            code: code,
            label: label,
            visible: false,
            discount: 0.0,
            active: false,
            approved: false,
            title: "",
            status: SubstitutionClaimStatus.planned
        )
    }
}
