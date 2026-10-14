import AcmePlatform
import Foundation

extension Labs {
    /// Where a strict reference range score is in its life cycle.
    enum StrictReferenceRangeScoreStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A strict reference range score as the reference range team keeps it.
    final class StrictReferenceRangeScore {
        var code: String
        var label: String
        var durationMinutes: Int
        var allergy: String
        var approved: Bool
        var description: String
        var budget: Double
        var externalRef: String
        var status: StrictReferenceRangeScoreStatus

        init(code: String, label: String, durationMinutes: Int, allergy: String, approved: Bool, description: String, budget: Double, externalRef: String, status: StrictReferenceRangeScoreStatus) {
            self.code = code
            self.label = label
            self.durationMinutes = durationMinutes
            self.allergy = allergy
            self.approved = approved
            self.description = description
            self.budget = budget
            self.externalRef = externalRef
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

        func canMoveTo(_ next: StrictReferenceRangeScoreStatus) -> Bool {
            switch status {
            case .planned:
                return next == StrictReferenceRangeScoreStatus.completed
            case .scheduled:
                return next == StrictReferenceRangeScoreStatus.inProgress || next == StrictReferenceRangeScoreStatus.cancelled
            case .inProgress:
                return next == StrictReferenceRangeScoreStatus.cancelled
            case .completed:
                return next == StrictReferenceRangeScoreStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictReferenceRangeScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict reference range score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedVolume() -> Double {
            return ((budget + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> StrictReferenceRangeScore {
            return StrictReferenceRangeScore(
                code: code,
                label: label,
                durationMinutes: durationMinutes,
                allergy: allergy,
                approved: approved,
                description: description,
                budget: budget,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a strict reference range score in status planned.
    static func newStrictReferenceRangeScore(_ code: String, label: String) -> StrictReferenceRangeScore {
        return StrictReferenceRangeScore(
            code: code,
            label: label,
            durationMinutes: 0,
            allergy: "",
            approved: false,
            description: "",
            budget: 0.0,
            externalRef: "",
            status: StrictReferenceRangeScoreStatus.planned
        )
    }
}
