import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a regional formulary milestone is in its life cycle.
    enum RegionalFormularyMilestoneStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A regional formulary milestone. Its code is unique within a tenant.
    final class RegionalFormularyMilestone {
        var code: String
        var label: String
        var payer: String
        var attempts: Int
        var title: String
        var locale: String
        var reviewer: String
        var phone: String
        var approved: Bool
        var retries: Int
        var dosageMg: Double
        var status: RegionalFormularyMilestoneStatus

        init(code: String, label: String, payer: String, attempts: Int, title: String, locale: String, reviewer: String, phone: String, approved: Bool, retries: Int, dosageMg: Double, status: RegionalFormularyMilestoneStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.attempts = attempts
            self.title = title
            self.locale = locale
            self.reviewer = reviewer
            self.phone = phone
            self.approved = approved
            self.retries = retries
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: RegionalFormularyMilestoneStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RegionalFormularyMilestoneStatus.rejected
            case .approved:
                return next == RegionalFormularyMilestoneStatus.rejected || next == RegionalFormularyMilestoneStatus.withdrawn
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

        func moveTo(_ next: RegionalFormularyMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional formulary milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netLoad() -> Double {
            return (Double(retries) * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> RegionalFormularyMilestone {
            return RegionalFormularyMilestone(
                code: code,
                label: label,
                payer: payer,
                attempts: attempts,
                title: title,
                locale: locale,
                reviewer: reviewer,
                phone: phone,
                approved: approved,
                retries: retries,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a regional formulary milestone in status proposed.
    static func newRegionalFormularyMilestone(_ code: String, label: String) -> RegionalFormularyMilestone {
        return RegionalFormularyMilestone(
            code: code,
            label: label,
            payer: "",
            attempts: 0,
            title: "",
            locale: "",
            reviewer: "",
            phone: "",
            approved: false,
            retries: 0,
            dosageMg: 0.0,
            status: RegionalFormularyMilestoneStatus.proposed
        )
    }
}
