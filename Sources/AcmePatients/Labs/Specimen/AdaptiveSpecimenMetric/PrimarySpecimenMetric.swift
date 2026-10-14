import AcmePlatform
import Foundation

extension Labs {
    /// Where a primary specimen metric is in its life cycle.
    enum PrimarySpecimenMetricStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a primary specimen metric and its current status.
    final class PrimarySpecimenMetric {
        var code: String
        var label: String
        var rate: Double
        var diagnosisCode: String
        var summary: String
        var phone: String
        var status: PrimarySpecimenMetricStatus

        init(code: String, label: String, rate: Double, diagnosisCode: String, summary: String, phone: String, status: PrimarySpecimenMetricStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.diagnosisCode = diagnosisCode
            self.summary = summary
            self.phone = phone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimarySpecimenMetricStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == PrimarySpecimenMetricStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimarySpecimenMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary specimen metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return rate
        }

        func copyValue() -> PrimarySpecimenMetric {
            return PrimarySpecimenMetric(
                code: code,
                label: label,
                rate: rate,
                diagnosisCode: diagnosisCode,
                summary: summary,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary specimen metric in status requested.
    static func newPrimarySpecimenMetric(_ code: String, label: String) -> PrimarySpecimenMetric {
        return PrimarySpecimenMetric(
            code: code,
            label: label,
            rate: 0.0,
            diagnosisCode: "",
            summary: "",
            phone: "",
            status: PrimarySpecimenMetricStatus.requested
        )
    }
}
