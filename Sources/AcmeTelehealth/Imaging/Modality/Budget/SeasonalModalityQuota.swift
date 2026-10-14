import AcmePlatform
import Foundation

extension Imaging {
    /// Where a seasonal modality quota is in its life cycle.
    enum SeasonalModalityQuotaStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A seasonal modality quota as the modality team keeps it.
    final class SeasonalModalityQuota {
        var code: String
        var label: String
        var floorValue: Double
        var rate: Double
        var acuity: Int
        var budget: Double
        var patientRef: String
        var category: String
        var status: SeasonalModalityQuotaStatus

        init(code: String, label: String, floorValue: Double, rate: Double, acuity: Int, budget: Double, patientRef: String, category: String, status: SeasonalModalityQuotaStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.rate = rate
            self.acuity = acuity
            self.budget = budget
            self.patientRef = patientRef
            self.category = category
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

        func canMoveTo(_ next: SeasonalModalityQuotaStatus) -> Bool {
            switch status {
            case .created:
                return next == SeasonalModalityQuotaStatus.validated || next == SeasonalModalityQuotaStatus.published
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == SeasonalModalityQuotaStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalModalityQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal modality quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("seasonal modality quota") \(code)"
        }

        func projectedVolume() -> Double {
            return ((budget + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalModalityQuota {
            return SeasonalModalityQuota(
                code: code,
                label: label,
                floorValue: floorValue,
                rate: rate,
                acuity: acuity,
                budget: budget,
                patientRef: patientRef,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a seasonal modality quota in status created.
    static func newSeasonalModalityQuota(_ code: String, label: String) -> SeasonalModalityQuota {
        return SeasonalModalityQuota(
            code: code,
            label: label,
            floorValue: 0.0,
            rate: 0.0,
            acuity: 0,
            budget: 0.0,
            patientRef: "",
            category: "",
            status: SeasonalModalityQuotaStatus.created
        )
    }
}
