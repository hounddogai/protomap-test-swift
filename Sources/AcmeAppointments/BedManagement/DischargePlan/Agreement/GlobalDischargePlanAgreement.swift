import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a global discharge plan agreement is in its life cycle.
    enum GlobalDischargePlanAgreementStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a global discharge plan agreement and its current status.
    final class GlobalDischargePlanAgreement {
        var code: String
        var label: String
        var copay: Double
        var payer: String
        var approved: Bool
        var allergy: String
        var acuity: Int
        var description: String
        var dosageMg: Double
        var refills: Int
        var status: GlobalDischargePlanAgreementStatus

        init(code: String, label: String, copay: Double, payer: String, approved: Bool, allergy: String, acuity: Int, description: String, dosageMg: Double, refills: Int, status: GlobalDischargePlanAgreementStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.payer = payer
            self.approved = approved
            self.allergy = allergy
            self.acuity = acuity
            self.description = description
            self.dosageMg = dosageMg
            self.refills = refills
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

        func canMoveTo(_ next: GlobalDischargePlanAgreementStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == GlobalDischargePlanAgreementStatus.cancelled
            case .inProgress:
                return next == GlobalDischargePlanAgreementStatus.completed
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

        func moveTo(_ next: GlobalDischargePlanAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global discharge plan agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("global discharge plan agreement") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((dosageMg + copay) * 100).rounded() / 100
        }

        func copyValue() -> GlobalDischargePlanAgreement {
            return GlobalDischargePlanAgreement(
                code: code,
                label: label,
                copay: copay,
                payer: payer,
                approved: approved,
                allergy: allergy,
                acuity: acuity,
                description: description,
                dosageMg: dosageMg,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global discharge plan agreement in status planned.
    static func newGlobalDischargePlanAgreement(_ code: String, label: String) -> GlobalDischargePlanAgreement {
        return GlobalDischargePlanAgreement(
            code: code,
            label: label,
            copay: 0.0,
            payer: "",
            approved: false,
            allergy: "",
            acuity: 0,
            description: "",
            dosageMg: 0.0,
            refills: 0,
            status: GlobalDischargePlanAgreementStatus.planned
        )
    }
}
