import AcmePlatform
import Foundation

extension Labs {
    /// Where a manual reference range forecast is in its life cycle.
    enum ManualReferenceRangeForecastStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One manual reference range forecast, with what the planners need to act on it.
    final class ManualReferenceRangeForecast {
        var code: String
        var label: String
        var allergy: String
        var segment: String
        var clinicianID: String
        var score: Double
        var status: ManualReferenceRangeForecastStatus

        init(code: String, label: String, allergy: String, segment: String, clinicianID: String, score: Double, status: ManualReferenceRangeForecastStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.segment = segment
            self.clinicianID = clinicianID
            self.score = score
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

        func canMoveTo(_ next: ManualReferenceRangeForecastStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ManualReferenceRangeForecastStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualReferenceRangeForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual reference range forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> ManualReferenceRangeForecast {
            return ManualReferenceRangeForecast(
                code: code,
                label: label,
                allergy: allergy,
                segment: segment,
                clinicianID: clinicianID,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a manual reference range forecast in status proposed.
    static func newManualReferenceRangeForecast(_ code: String, label: String) -> ManualReferenceRangeForecast {
        return ManualReferenceRangeForecast(
            code: code,
            label: label,
            allergy: "",
            segment: "",
            clinicianID: "",
            score: 0.0,
            status: ManualReferenceRangeForecastStatus.proposed
        )
    }
}
