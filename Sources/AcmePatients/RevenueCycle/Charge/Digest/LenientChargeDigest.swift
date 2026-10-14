import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a lenient charge digest is in its life cycle.
    enum LenientChargeDigestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One lenient charge digest, with what the planners need to act on it.
    final class LenientChargeDigest {
        var code: String
        var label: String
        var externalRef: String
        var ownerID: String
        var category: String
        var diagnosisCode: String
        var discount: Double
        var status: LenientChargeDigestStatus

        init(code: String, label: String, externalRef: String, ownerID: String, category: String, diagnosisCode: String, discount: Double, status: LenientChargeDigestStatus) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.ownerID = ownerID
            self.category = category
            self.diagnosisCode = diagnosisCode
            self.discount = discount
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

        func canMoveTo(_ next: LenientChargeDigestStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LenientChargeDigestStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: LenientChargeDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient charge digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("lenient charge digest") \(code)"
        }

        func measuredValue() -> Double {
            return discount
        }

        func copyValue() -> LenientChargeDigest {
            return LenientChargeDigest(
                code: code,
                label: label,
                externalRef: externalRef,
                ownerID: ownerID,
                category: category,
                diagnosisCode: diagnosisCode,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a lenient charge digest in status proposed.
    static func newLenientChargeDigest(_ code: String, label: String) -> LenientChargeDigest {
        return LenientChargeDigest(
            code: code,
            label: label,
            externalRef: "",
            ownerID: "",
            category: "",
            diagnosisCode: "",
            discount: 0.0,
            status: LenientChargeDigestStatus.proposed
        )
    }
}
