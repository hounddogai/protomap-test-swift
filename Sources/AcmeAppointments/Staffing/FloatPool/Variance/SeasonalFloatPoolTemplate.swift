import AcmePlatform
import Foundation

extension Staffing {
    /// Where a seasonal float pool template is in its life cycle.
    enum SeasonalFloatPoolTemplateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a seasonal float pool template and its current status.
    final class SeasonalFloatPoolTemplate {
        var code: String
        var label: String
        var diagnosisCode: String
        var discount: Double
        var limit: Int
        var ratio: Double
        var status: SeasonalFloatPoolTemplateStatus

        init(code: String, label: String, diagnosisCode: String, discount: Double, limit: Int, ratio: Double, status: SeasonalFloatPoolTemplateStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.discount = discount
            self.limit = limit
            self.ratio = ratio
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalFloatPoolTemplateStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == SeasonalFloatPoolTemplateStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalFloatPoolTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal float pool template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("seasonal float pool template") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((Double(limit) + discount) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalFloatPoolTemplate {
            return SeasonalFloatPoolTemplate(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                discount: discount,
                limit: limit,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal float pool template in status new.
    static func newSeasonalFloatPoolTemplate(_ code: String, label: String) -> SeasonalFloatPoolTemplate {
        return SeasonalFloatPoolTemplate(
            code: code,
            label: label,
            diagnosisCode: "",
            discount: 0.0,
            limit: 0,
            ratio: 0.0,
            status: SeasonalFloatPoolTemplateStatus.new
        )
    }
}
