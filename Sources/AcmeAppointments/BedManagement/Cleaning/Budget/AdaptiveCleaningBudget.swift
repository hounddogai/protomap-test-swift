import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive cleaning budget is in its life cycle.
    enum AdaptiveCleaningBudgetStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A adaptive cleaning budget as the cleaning team keeps it.
    final class AdaptiveCleaningBudget {
        var code: String
        var label: String
        var patientRef: String
        var currency: String
        var floorValue: Double
        var cost: Double
        var allergy: String
        var durationMinutes: Int
        var status: AdaptiveCleaningBudgetStatus

        init(code: String, label: String, patientRef: String, currency: String, floorValue: Double, cost: Double, allergy: String, durationMinutes: Int, status: AdaptiveCleaningBudgetStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.currency = currency
            self.floorValue = floorValue
            self.cost = cost
            self.allergy = allergy
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

        func canMoveTo(_ next: AdaptiveCleaningBudgetStatus) -> Bool {
            switch status {
            case .created:
                return next == AdaptiveCleaningBudgetStatus.published || next == AdaptiveCleaningBudgetStatus.retired
            case .validated:
                return next == AdaptiveCleaningBudgetStatus.published
            case .published:
                return next == AdaptiveCleaningBudgetStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveCleaningBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive cleaning budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedTotal() -> Double {
            return ((cost + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveCleaningBudget {
            return AdaptiveCleaningBudget(
                code: code,
                label: label,
                patientRef: patientRef,
                currency: currency,
                floorValue: floorValue,
                cost: cost,
                allergy: allergy,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive cleaning budget in status created.
    static func newAdaptiveCleaningBudget(_ code: String, label: String) -> AdaptiveCleaningBudget {
        return AdaptiveCleaningBudget(
            code: code,
            label: label,
            patientRef: "",
            currency: "",
            floorValue: 0.0,
            cost: 0.0,
            allergy: "",
            durationMinutes: 0,
            status: AdaptiveCleaningBudgetStatus.created
        )
    }
}
