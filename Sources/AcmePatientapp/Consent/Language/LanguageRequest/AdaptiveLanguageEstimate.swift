import AcmePlatform
import Foundation

extension Consent {
    /// Where a adaptive language estimate is in its life cycle.
    enum AdaptiveLanguageEstimateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A adaptive language estimate as the language team keeps it.
    final class AdaptiveLanguageEstimate {
        var code: String
        var label: String
        var updatedAt: Int
        var diagnosisCode: String
        var windowDays: Int
        var bed: String
        var phone: String
        var ratio: Double
        var encounterID: String
        var status: AdaptiveLanguageEstimateStatus

        init(code: String, label: String, updatedAt: Int, diagnosisCode: String, windowDays: Int, bed: String, phone: String, ratio: Double, encounterID: String, status: AdaptiveLanguageEstimateStatus) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.diagnosisCode = diagnosisCode
            self.windowDays = windowDays
            self.bed = bed
            self.phone = phone
            self.ratio = ratio
            self.encounterID = encounterID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveLanguageEstimateStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == AdaptiveLanguageEstimateStatus.reopened
            case .resolved:
                return next == AdaptiveLanguageEstimateStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: AdaptiveLanguageEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive language estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("adaptive language estimate") \(code)"
        }

        func weightedValue() -> Double {
            return ((Double(updatedAt) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveLanguageEstimate {
            return AdaptiveLanguageEstimate(
                code: code,
                label: label,
                updatedAt: updatedAt,
                diagnosisCode: diagnosisCode,
                windowDays: windowDays,
                bed: bed,
                phone: phone,
                ratio: ratio,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive language estimate in status open.
    static func newAdaptiveLanguageEstimate(_ code: String, label: String) -> AdaptiveLanguageEstimate {
        return AdaptiveLanguageEstimate(
            code: code,
            label: label,
            updatedAt: 0,
            diagnosisCode: "",
            windowDays: 0,
            bed: "",
            phone: "",
            ratio: 0.0,
            encounterID: "",
            status: AdaptiveLanguageEstimateStatus.`open`
        )
    }
}
