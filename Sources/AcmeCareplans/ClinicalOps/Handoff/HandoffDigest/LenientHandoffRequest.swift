import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a lenient handoff request is in its life cycle.
    enum LenientHandoffRequestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A lenient handoff request. Its code is unique within a tenant.
    final class LenientHandoffRequest {
        var code: String
        var label: String
        var diagnosisCode: String
        var segment: String
        var locale: String
        var amount: Double
        var status: LenientHandoffRequestStatus

        init(code: String, label: String, diagnosisCode: String, segment: String, locale: String, amount: Double, status: LenientHandoffRequestStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.segment = segment
            self.locale = locale
            self.amount = amount
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

        func canMoveTo(_ next: LenientHandoffRequestStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == LenientHandoffRequestStatus.published || next == LenientHandoffRequestStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: LenientHandoffRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient handoff request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> LenientHandoffRequest {
            return LenientHandoffRequest(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                segment: segment,
                locale: locale,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a lenient handoff request in status created.
    static func newLenientHandoffRequest(_ code: String, label: String) -> LenientHandoffRequest {
        return LenientHandoffRequest(
            code: code,
            label: label,
            diagnosisCode: "",
            segment: "",
            locale: "",
            amount: 0.0,
            status: LenientHandoffRequestStatus.created
        )
    }
}
