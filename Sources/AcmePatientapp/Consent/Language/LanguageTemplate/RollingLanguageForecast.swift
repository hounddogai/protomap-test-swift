import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling language forecast is in its life cycle.
    enum RollingLanguageForecastStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A rolling language forecast as the language team keeps it.
    final class RollingLanguageForecast {
        var code: String
        var label: String
        var attributes: [String: String]
        var segment: String
        var patientRef: String
        var diagnosisCode: String
        var phone: String
        var quantity: Int
        var status: RollingLanguageForecastStatus

        init(code: String, label: String, attributes: [String: String], segment: String, patientRef: String, diagnosisCode: String, phone: String, quantity: Int, status: RollingLanguageForecastStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.segment = segment
            self.patientRef = patientRef
            self.diagnosisCode = diagnosisCode
            self.phone = phone
            self.quantity = quantity
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

        func canMoveTo(_ next: RollingLanguageForecastStatus) -> Bool {
            switch status {
            case .planned:
                return next == RollingLanguageForecastStatus.scheduled || next == RollingLanguageForecastStatus.inProgress
            case .scheduled:
                return next == RollingLanguageForecastStatus.inProgress || next == RollingLanguageForecastStatus.cancelled
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: RollingLanguageForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling language forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> RollingLanguageForecast {
            return RollingLanguageForecast(
                code: code,
                label: label,
                attributes: attributes,
                segment: segment,
                patientRef: patientRef,
                diagnosisCode: diagnosisCode,
                phone: phone,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a rolling language forecast in status planned.
    static func newRollingLanguageForecast(_ code: String, label: String) -> RollingLanguageForecast {
        return RollingLanguageForecast(
            code: code,
            label: label,
            attributes: [:],
            segment: "",
            patientRef: "",
            diagnosisCode: "",
            phone: "",
            quantity: 0,
            status: RollingLanguageForecastStatus.planned
        )
    }
}
