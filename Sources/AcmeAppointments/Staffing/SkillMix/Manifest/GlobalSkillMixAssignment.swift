import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global skill mix assignment is in its life cycle.
    enum GlobalSkillMixAssignmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A global skill mix assignment as the skill mix team keeps it.
    final class GlobalSkillMixAssignment {
        var code: String
        var title: String
        var visitMinutes: Int
        var archived: Bool
        var unit: String
        var score: Double
        var currency: String
        var threshold: Double
        var status: GlobalSkillMixAssignmentStatus

        init(code: String, title: String, visitMinutes: Int, archived: Bool, unit: String, score: Double, currency: String, threshold: Double, status: GlobalSkillMixAssignmentStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.archived = archived
            self.unit = unit
            self.score = score
            self.currency = currency
            self.threshold = threshold
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalSkillMixAssignmentStatus) -> Bool {
            switch status {
            case .requested:
                return next == GlobalSkillMixAssignmentStatus.granted
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: GlobalSkillMixAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global skill mix assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedVolume() -> Double {
            return (score * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> GlobalSkillMixAssignment {
            return GlobalSkillMixAssignment(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                archived: archived,
                unit: unit,
                score: score,
                currency: currency,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a global skill mix assignment in status requested.
    static func newGlobalSkillMixAssignment(_ code: String, title: String) -> GlobalSkillMixAssignment {
        return GlobalSkillMixAssignment(
            code: code,
            title: title,
            visitMinutes: 0,
            archived: false,
            unit: "",
            score: 0.0,
            currency: "",
            threshold: 0.0,
            status: GlobalSkillMixAssignmentStatus.requested
        )
    }
}
