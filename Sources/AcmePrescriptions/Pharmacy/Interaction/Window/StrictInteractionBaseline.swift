import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a strict interaction baseline is in its life cycle.
    enum StrictInteractionBaselineStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A strict interaction baseline as the interaction team keeps it.
    final class StrictInteractionBaseline {
        var code: String
        var label: String
        var dosageMg: Double
        var title: String
        var category: String
        var status: StrictInteractionBaselineStatus

        init(code: String, label: String, dosageMg: Double, title: String, category: String, status: StrictInteractionBaselineStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.title = title
            self.category = category
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

        func canMoveTo(_ next: StrictInteractionBaselineStatus) -> Bool {
            switch status {
            case .planned:
                return next == StrictInteractionBaselineStatus.inProgress
            case .scheduled:
                return next == StrictInteractionBaselineStatus.inProgress || next == StrictInteractionBaselineStatus.cancelled
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == StrictInteractionBaselineStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictInteractionBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict interaction baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> StrictInteractionBaseline {
            return StrictInteractionBaseline(
                code: code,
                label: label,
                dosageMg: dosageMg,
                title: title,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a strict interaction baseline in status planned.
    static func newStrictInteractionBaseline(_ code: String, label: String) -> StrictInteractionBaseline {
        return StrictInteractionBaseline(
            code: code,
            label: label,
            dosageMg: 0.0,
            title: "",
            category: "",
            status: StrictInteractionBaselineStatus.planned
        )
    }
}
