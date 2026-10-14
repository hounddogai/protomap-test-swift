import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a seasonal remittance group is in its life cycle.
    enum SeasonalRemittanceGroupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One seasonal remittance group, with what the planners need to act on it.
    final class SeasonalRemittanceGroup {
        var code: String
        var label: String
        var allergy: String
        var priority: Int
        var floorValue: Double
        var status: SeasonalRemittanceGroupStatus

        init(code: String, label: String, allergy: String, priority: Int, floorValue: Double, status: SeasonalRemittanceGroupStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.priority = priority
            self.floorValue = floorValue
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

        func canMoveTo(_ next: SeasonalRemittanceGroupStatus) -> Bool {
            switch status {
            case .planned:
                return next == SeasonalRemittanceGroupStatus.scheduled || next == SeasonalRemittanceGroupStatus.inProgress
            case .scheduled:
                return next == SeasonalRemittanceGroupStatus.inProgress || next == SeasonalRemittanceGroupStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == SeasonalRemittanceGroupStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalRemittanceGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal remittance group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("seasonal remittance group") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((floorValue - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalRemittanceGroup {
            return SeasonalRemittanceGroup(
                code: code,
                label: label,
                allergy: allergy,
                priority: priority,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal remittance group in status planned.
    static func newSeasonalRemittanceGroup(_ code: String, label: String) -> SeasonalRemittanceGroup {
        return SeasonalRemittanceGroup(
            code: code,
            label: label,
            allergy: "",
            priority: 0,
            floorValue: 0.0,
            status: SeasonalRemittanceGroupStatus.planned
        )
    }
}
