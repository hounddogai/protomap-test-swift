import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen notice is in its life cycle.
    enum SpecimenNoticeStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a specimen notice and its current status.
    final class SpecimenNotice {
        var code: String
        var label: String
        var retries: Int
        var rate: Double
        var ceiling: Double
        var locale: String
        var margin: Double
        var unit: String
        var diagnosisCode: String
        var status: SpecimenNoticeStatus

        init(code: String, label: String, retries: Int, rate: Double, ceiling: Double, locale: String, margin: Double, unit: String, diagnosisCode: String, status: SpecimenNoticeStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.rate = rate
            self.ceiling = ceiling
            self.locale = locale
            self.margin = margin
            self.unit = unit
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: SpecimenNoticeStatus) -> Bool {
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
                return next == SpecimenNoticeStatus.rejected || next == SpecimenNoticeStatus.withdrawn
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

        func moveTo(_ next: SpecimenNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netLoad() -> Double {
            return (rate * ceiling * 100).rounded() / 100
        }

        func copyValue() -> SpecimenNotice {
            return SpecimenNotice(
                code: code,
                label: label,
                retries: retries,
                rate: rate,
                ceiling: ceiling,
                locale: locale,
                margin: margin,
                unit: unit,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a specimen notice in status proposed.
    static func newSpecimenNotice(_ code: String, label: String) -> SpecimenNotice {
        return SpecimenNotice(
            code: code,
            label: label,
            retries: 0,
            rate: 0.0,
            ceiling: 0.0,
            locale: "",
            margin: 0.0,
            unit: "",
            diagnosisCode: "",
            status: SpecimenNoticeStatus.proposed
        )
    }
}
