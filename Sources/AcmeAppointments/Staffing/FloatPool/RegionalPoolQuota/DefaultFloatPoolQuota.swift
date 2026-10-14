import AcmePlatform
import Foundation

extension Staffing {
    /// Where a default float pool quota is in its life cycle.
    enum DefaultFloatPoolQuotaStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a default float pool quota and its current status.
    final class DefaultFloatPoolQuota {
        var code: String
        var name: String
        var label: String
        var maximum: Double
        var patientRef: String
        var locale: String
        var segment: String
        var diagnosisCode: String
        var status: DefaultFloatPoolQuotaStatus

        init(code: String, name: String, label: String, maximum: Double, patientRef: String, locale: String, segment: String, diagnosisCode: String, status: DefaultFloatPoolQuotaStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.maximum = maximum
            self.patientRef = patientRef
            self.locale = locale
            self.segment = segment
            self.diagnosisCode = diagnosisCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultFloatPoolQuotaStatus) -> Bool {
            switch status {
            case .idle:
                return next == DefaultFloatPoolQuotaStatus.draining
            case .warming:
                return next == DefaultFloatPoolQuotaStatus.ready
            case .ready:
                return next == DefaultFloatPoolQuotaStatus.draining || next == DefaultFloatPoolQuotaStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: DefaultFloatPoolQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default float pool quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return maximum
        }

        func copyValue() -> DefaultFloatPoolQuota {
            return DefaultFloatPoolQuota(
                code: code,
                name: name,
                label: label,
                maximum: maximum,
                patientRef: patientRef,
                locale: locale,
                segment: segment,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a default float pool quota in status idle.
    static func newDefaultFloatPoolQuota(_ code: String, name: String) -> DefaultFloatPoolQuota {
        return DefaultFloatPoolQuota(
            code: code,
            name: name,
            label: "",
            maximum: 0.0,
            patientRef: "",
            locale: "",
            segment: "",
            diagnosisCode: "",
            status: DefaultFloatPoolQuotaStatus.idle
        )
    }
}
