import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a capped goal agreement is in its life cycle.
    enum CappedGoalAgreementStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One capped goal agreement, with what the planners need to act on it.
    final class CappedGoalAgreement {
        var code: String
        var label: String
        var weight: Double
        var score: Double
        var durationMinutes: Int
        var archived: Bool
        var status: CappedGoalAgreementStatus

        init(code: String, label: String, weight: Double, score: Double, durationMinutes: Int, archived: Bool, status: CappedGoalAgreementStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.score = score
            self.durationMinutes = durationMinutes
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedGoalAgreementStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: CappedGoalAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped goal agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedTotal() -> Double {
            return (weight * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> CappedGoalAgreement {
            return CappedGoalAgreement(
                code: code,
                label: label,
                weight: weight,
                score: score,
                durationMinutes: durationMinutes,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a capped goal agreement in status proposed.
    static func newCappedGoalAgreement(_ code: String, label: String) -> CappedGoalAgreement {
        return CappedGoalAgreement(
            code: code,
            label: label,
            weight: 0.0,
            score: 0.0,
            durationMinutes: 0,
            archived: false,
            status: CappedGoalAgreementStatus.proposed
        )
    }
}
