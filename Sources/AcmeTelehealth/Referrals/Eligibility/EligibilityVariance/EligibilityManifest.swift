import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility manifest is in its life cycle.
    enum EligibilityManifestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A eligibility manifest. Its code is unique within a tenant.
    final class EligibilityManifest {
        var code: String
        var title: String
        var phone: String
        var procedureCode: String
        var approved: Bool
        var allergy: String
        var quantity: Int
        var status: EligibilityManifestStatus

        init(code: String, title: String, phone: String, procedureCode: String, approved: Bool, allergy: String, quantity: Int, status: EligibilityManifestStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.procedureCode = procedureCode
            self.approved = approved
            self.allergy = allergy
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

        func canMoveTo(_ next: EligibilityManifestStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == EligibilityManifestStatus.completed || next == EligibilityManifestStatus.cancelled
            case .inProgress:
                return next == EligibilityManifestStatus.completed || next == EligibilityManifestStatus.cancelled
            case .completed:
                return next == EligibilityManifestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilityManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("eligibility manifest") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> EligibilityManifest {
            return EligibilityManifest(
                code: code,
                title: title,
                phone: phone,
                procedureCode: procedureCode,
                approved: approved,
                allergy: allergy,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a eligibility manifest in status planned.
    static func newEligibilityManifest(_ code: String, title: String) -> EligibilityManifest {
        return EligibilityManifest(
            code: code,
            title: title,
            phone: "",
            procedureCode: "",
            approved: false,
            allergy: "",
            quantity: 0,
            status: EligibilityManifestStatus.planned
        )
    }
}
