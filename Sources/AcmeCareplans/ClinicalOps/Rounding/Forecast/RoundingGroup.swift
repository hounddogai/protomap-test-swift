import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding group is in its life cycle.
    enum RoundingGroupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One rounding group, with what the planners need to act on it.
    final class RoundingGroup {
        var code: String
        var name: String
        var diagnosisCode: String
        var notes: String
        var allergy: String
        var retries: Int
        var status: RoundingGroupStatus

        init(code: String, name: String, diagnosisCode: String, notes: String, allergy: String, retries: Int, status: RoundingGroupStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.notes = notes
            self.allergy = allergy
            self.retries = retries
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

        func canMoveTo(_ next: RoundingGroupStatus) -> Bool {
            switch status {
            case .planned:
                return next == RoundingGroupStatus.scheduled || next == RoundingGroupStatus.completed
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == RoundingGroupStatus.completed || next == RoundingGroupStatus.cancelled
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

        func moveTo(_ next: RoundingGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(retries)
        }

        func copyValue() -> RoundingGroup {
            return RoundingGroup(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                notes: notes,
                allergy: allergy,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rounding group in status planned.
    static func newRoundingGroup(_ code: String, name: String) -> RoundingGroup {
        return RoundingGroup(
            code: code,
            name: name,
            diagnosisCode: "",
            notes: "",
            allergy: "",
            retries: 0,
            status: RoundingGroupStatus.planned
        )
    }
}
