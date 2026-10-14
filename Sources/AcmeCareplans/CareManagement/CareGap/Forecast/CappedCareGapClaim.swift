import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a capped care gap claim is in its life cycle.
    enum CappedCareGapClaimStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a capped care gap claim and its current status.
    final class CappedCareGapClaim {
        var code: String
        var label: String
        var dosageMg: Double
        var discount: Double
        var archived: Bool
        var pinned: Bool
        var timezone: String
        var quantity: Int
        var diagnosisCode: String
        var locale: String
        var status: CappedCareGapClaimStatus

        init(code: String, label: String, dosageMg: Double, discount: Double, archived: Bool, pinned: Bool, timezone: String, quantity: Int, diagnosisCode: String, locale: String, status: CappedCareGapClaimStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.discount = discount
            self.archived = archived
            self.pinned = pinned
            self.timezone = timezone
            self.quantity = quantity
            self.diagnosisCode = diagnosisCode
            self.locale = locale
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

        func canMoveTo(_ next: CappedCareGapClaimStatus) -> Bool {
            switch status {
            case .created:
                return next == CappedCareGapClaimStatus.validated || next == CappedCareGapClaimStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == CappedCareGapClaimStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedCareGapClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped care gap claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedExposure() -> Double {
            return ((dosageMg - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> CappedCareGapClaim {
            return CappedCareGapClaim(
                code: code,
                label: label,
                dosageMg: dosageMg,
                discount: discount,
                archived: archived,
                pinned: pinned,
                timezone: timezone,
                quantity: quantity,
                diagnosisCode: diagnosisCode,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a capped care gap claim in status created.
    static func newCappedCareGapClaim(_ code: String, label: String) -> CappedCareGapClaim {
        return CappedCareGapClaim(
            code: code,
            label: label,
            dosageMg: 0.0,
            discount: 0.0,
            archived: false,
            pinned: false,
            timezone: "",
            quantity: 0,
            diagnosisCode: "",
            locale: "",
            status: CappedCareGapClaimStatus.created
        )
    }
}
