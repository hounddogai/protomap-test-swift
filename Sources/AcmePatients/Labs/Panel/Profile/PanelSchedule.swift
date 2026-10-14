import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel schedule is in its life cycle.
    enum PanelScheduleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a panel schedule and its current status.
    final class PanelSchedule {
        var code: String
        var label: String
        var ceiling: Double
        var budget: Double
        var currency: String
        var timezone: String
        var maximum: Double
        var externalRef: String
        var ownerID: String
        var status: PanelScheduleStatus

        init(code: String, label: String, ceiling: Double, budget: Double, currency: String, timezone: String, maximum: Double, externalRef: String, ownerID: String, status: PanelScheduleStatus) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.budget = budget
            self.currency = currency
            self.timezone = timezone
            self.maximum = maximum
            self.externalRef = externalRef
            self.ownerID = ownerID
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

        func canMoveTo(_ next: PanelScheduleStatus) -> Bool {
            switch status {
            case .created:
                return next == PanelScheduleStatus.validated || next == PanelScheduleStatus.published
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == PanelScheduleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PanelScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedVolume() -> Double {
            return ((budget - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> PanelSchedule {
            return PanelSchedule(
                code: code,
                label: label,
                ceiling: ceiling,
                budget: budget,
                currency: currency,
                timezone: timezone,
                maximum: maximum,
                externalRef: externalRef,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a panel schedule in status created.
    static func newPanelSchedule(_ code: String, label: String) -> PanelSchedule {
        return PanelSchedule(
            code: code,
            label: label,
            ceiling: 0.0,
            budget: 0.0,
            currency: "",
            timezone: "",
            maximum: 0.0,
            externalRef: "",
            ownerID: "",
            status: PanelScheduleStatus.created
        )
    }
}
