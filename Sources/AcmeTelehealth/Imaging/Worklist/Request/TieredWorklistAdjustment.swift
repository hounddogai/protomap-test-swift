import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered worklist adjustment is in its life cycle.
    enum TieredWorklistAdjustmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One tiered worklist adjustment, with what the planners need to act on it.
    final class TieredWorklistAdjustment {
        var code: String
        var label: String
        var margin: Double
        var specialty: String
        var name: String
        var country: String
        var status: TieredWorklistAdjustmentStatus

        init(code: String, label: String, margin: Double, specialty: String, name: String, country: String, status: TieredWorklistAdjustmentStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.specialty = specialty
            self.name = name
            self.country = country
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

        func canMoveTo(_ next: TieredWorklistAdjustmentStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
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
                return next == TieredWorklistAdjustmentStatus.completed
            case .completed:
                return next == TieredWorklistAdjustmentStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredWorklistAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered worklist adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("tiered worklist adjustment") \(code)"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> TieredWorklistAdjustment {
            return TieredWorklistAdjustment(
                code: code,
                label: label,
                margin: margin,
                specialty: specialty,
                name: name,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a tiered worklist adjustment in status planned.
    static func newTieredWorklistAdjustment(_ code: String, label: String) -> TieredWorklistAdjustment {
        return TieredWorklistAdjustment(
            code: code,
            label: label,
            margin: 0.0,
            specialty: "",
            name: "",
            country: "",
            status: TieredWorklistAdjustmentStatus.planned
        )
    }
}
