import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession cycle is in its life cycle.
    enum AccessionCycleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One accession cycle, with what the planners need to act on it.
    final class AccessionCycle {
        var code: String
        var label: String
        var archived: Bool
        var budget: Double
        var diagnosisCode: String
        var visible: Bool
        var version: Int
        var locale: String
        var durationMinutes: Int
        var status: AccessionCycleStatus

        init(code: String, label: String, archived: Bool, budget: Double, diagnosisCode: String, visible: Bool, version: Int, locale: String, durationMinutes: Int, status: AccessionCycleStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.budget = budget
            self.diagnosisCode = diagnosisCode
            self.visible = visible
            self.version = version
            self.locale = locale
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: AccessionCycleStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == AccessionCycleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("accession cycle") \(code)"
        }

        func projectedLoad() -> Double {
            return (Double(version) * budget * 100).rounded() / 100
        }

        func copyValue() -> AccessionCycle {
            return AccessionCycle(
                code: code,
                label: label,
                archived: archived,
                budget: budget,
                diagnosisCode: diagnosisCode,
                visible: visible,
                version: version,
                locale: locale,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a accession cycle in status planned.
    static func newAccessionCycle(_ code: String, label: String) -> AccessionCycle {
        return AccessionCycle(
            code: code,
            label: label,
            archived: false,
            budget: 0.0,
            diagnosisCode: "",
            visible: false,
            version: 0,
            locale: "",
            durationMinutes: 0,
            status: AccessionCycleStatus.planned
        )
    }
}
