import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study target is in its life cycle.
    enum StudyTargetStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One study target, with what the planners need to act on it.
    final class StudyTarget {
        var code: String
        var label: String
        var weight: Double
        var ceiling: Double
        var encounterID: String
        var durationMinutes: Int
        var status: StudyTargetStatus

        init(code: String, label: String, weight: Double, ceiling: Double, encounterID: String, durationMinutes: Int, status: StudyTargetStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.ceiling = ceiling
            self.encounterID = encounterID
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: StudyTargetStatus) -> Bool {
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
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == StudyTargetStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StudyTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedValue() -> Double {
            return (ceiling * weight * 100).rounded() / 100
        }

        func copyValue() -> StudyTarget {
            return StudyTarget(
                code: code,
                label: label,
                weight: weight,
                ceiling: ceiling,
                encounterID: encounterID,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a study target in status created.
    static func newStudyTarget(_ code: String, label: String) -> StudyTarget {
        return StudyTarget(
            code: code,
            label: label,
            weight: 0.0,
            ceiling: 0.0,
            encounterID: "",
            durationMinutes: 0,
            status: StudyTargetStatus.created
        )
    }
}
