import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global acuity plan exception is in its life cycle.
    enum GlobalAcuityPlanExceptionStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One global acuity plan exception, with what the planners need to act on it.
    final class GlobalAcuityPlanException {
        var code: String
        var title: String
        var contactEmail: String
        var margin: Double
        var cost: Double
        var weight: Double
        var allergy: String
        var summary: String
        var status: GlobalAcuityPlanExceptionStatus

        init(code: String, title: String, contactEmail: String, margin: Double, cost: Double, weight: Double, allergy: String, summary: String, status: GlobalAcuityPlanExceptionStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.margin = margin
            self.cost = cost
            self.weight = weight
            self.allergy = allergy
            self.summary = summary
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalAcuityPlanExceptionStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == GlobalAcuityPlanExceptionStatus.revoked || next == GlobalAcuityPlanExceptionStatus.expired
            case .revoked:
                return next == GlobalAcuityPlanExceptionStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalAcuityPlanExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global acuity plan exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveExposure() -> Double {
            return ((cost - weight) * 100).rounded() / 100
        }

        func copyValue() -> GlobalAcuityPlanException {
            return GlobalAcuityPlanException(
                code: code,
                title: title,
                contactEmail: contactEmail,
                margin: margin,
                cost: cost,
                weight: weight,
                allergy: allergy,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global acuity plan exception in status requested.
    static func newGlobalAcuityPlanException(_ code: String, title: String) -> GlobalAcuityPlanException {
        return GlobalAcuityPlanException(
            code: code,
            title: title,
            contactEmail: "",
            margin: 0.0,
            cost: 0.0,
            weight: 0.0,
            allergy: "",
            summary: "",
            status: GlobalAcuityPlanExceptionStatus.requested
        )
    }
}
