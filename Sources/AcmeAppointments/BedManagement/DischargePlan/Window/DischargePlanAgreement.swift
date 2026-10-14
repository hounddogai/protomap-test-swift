import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan agreement is in its life cycle.
    enum DischargePlanAgreementStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a discharge plan agreement and its current status.
    final class DischargePlanAgreement {
        var code: String
        var label: String
        var weight: Double
        var updatedAt: Int
        var acuity: Int
        var copay: Double
        var ownerID: String
        var country: String
        var ceiling: Double
        var status: DischargePlanAgreementStatus

        init(code: String, label: String, weight: Double, updatedAt: Int, acuity: Int, copay: Double, ownerID: String, country: String, ceiling: Double, status: DischargePlanAgreementStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.updatedAt = updatedAt
            self.acuity = acuity
            self.copay = copay
            self.ownerID = ownerID
            self.country = country
            self.ceiling = ceiling
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

        func canMoveTo(_ next: DischargePlanAgreementStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == DischargePlanAgreementStatus.suspended
            case .active:
                return next == DischargePlanAgreementStatus.suspended
            case .suspended:
                return next == DischargePlanAgreementStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DischargePlanAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveLoad() -> Double {
            return ((weight - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanAgreement {
            return DischargePlanAgreement(
                code: code,
                label: label,
                weight: weight,
                updatedAt: updatedAt,
                acuity: acuity,
                copay: copay,
                ownerID: ownerID,
                country: country,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a discharge plan agreement in status draft.
    static func newDischargePlanAgreement(_ code: String, label: String) -> DischargePlanAgreement {
        return DischargePlanAgreement(
            code: code,
            label: label,
            weight: 0.0,
            updatedAt: 0,
            acuity: 0,
            copay: 0.0,
            ownerID: "",
            country: "",
            ceiling: 0.0,
            status: DischargePlanAgreementStatus.draft
        )
    }
}
