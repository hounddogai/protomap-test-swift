import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a weighted rounding preference is in its life cycle.
    enum WeightedRoundingPreferenceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One weighted rounding preference, with what the planners need to act on it.
    final class WeightedRoundingPreference {
        var code: String
        var label: String
        var ceiling: Double
        var rate: Double
        var procedureCode: String
        var attempts: Int
        var region: String
        var status: WeightedRoundingPreferenceStatus

        init(code: String, label: String, ceiling: Double, rate: Double, procedureCode: String, attempts: Int, region: String, status: WeightedRoundingPreferenceStatus) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.rate = rate
            self.procedureCode = procedureCode
            self.attempts = attempts
            self.region = region
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedRoundingPreferenceStatus) -> Bool {
            switch status {
            case .proposed:
                return next == WeightedRoundingPreferenceStatus.withdrawn
            case .approved:
                return next == WeightedRoundingPreferenceStatus.rejected || next == WeightedRoundingPreferenceStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: WeightedRoundingPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted rounding preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netValue() -> Double {
            return (Double(attempts) * rate * 100).rounded() / 100
        }

        func copyValue() -> WeightedRoundingPreference {
            return WeightedRoundingPreference(
                code: code,
                label: label,
                ceiling: ceiling,
                rate: rate,
                procedureCode: procedureCode,
                attempts: attempts,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a weighted rounding preference in status proposed.
    static func newWeightedRoundingPreference(_ code: String, label: String) -> WeightedRoundingPreference {
        return WeightedRoundingPreference(
            code: code,
            label: label,
            ceiling: 0.0,
            rate: 0.0,
            procedureCode: "",
            attempts: 0,
            region: "",
            status: WeightedRoundingPreferenceStatus.proposed
        )
    }
}
