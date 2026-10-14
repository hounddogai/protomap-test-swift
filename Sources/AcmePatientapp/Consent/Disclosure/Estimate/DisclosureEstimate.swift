import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure estimate is in its life cycle.
    enum DisclosureEstimateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a disclosure estimate and its current status.
    final class DisclosureEstimate {
        var code: String
        var label: String
        var amount: Double
        var description: String
        var maximum: Double
        var checksum: String
        var diagnosisCode: String
        var phone: String
        var specialty: String
        var status: DisclosureEstimateStatus

        init(code: String, label: String, amount: Double, description: String, maximum: Double, checksum: String, diagnosisCode: String, phone: String, specialty: String, status: DisclosureEstimateStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.description = description
            self.maximum = maximum
            self.checksum = checksum
            self.diagnosisCode = diagnosisCode
            self.phone = phone
            self.specialty = specialty
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DisclosureEstimateStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == DisclosureEstimateStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DisclosureEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("disclosure estimate") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((amount + maximum) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureEstimate {
            return DisclosureEstimate(
                code: code,
                label: label,
                amount: amount,
                description: description,
                maximum: maximum,
                checksum: checksum,
                diagnosisCode: diagnosisCode,
                phone: phone,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a disclosure estimate in status draft.
    static func newDisclosureEstimate(_ code: String, label: String) -> DisclosureEstimate {
        return DisclosureEstimate(
            code: code,
            label: label,
            amount: 0.0,
            description: "",
            maximum: 0.0,
            checksum: "",
            diagnosisCode: "",
            phone: "",
            specialty: "",
            status: DisclosureEstimateStatus.draft
        )
    }
}
