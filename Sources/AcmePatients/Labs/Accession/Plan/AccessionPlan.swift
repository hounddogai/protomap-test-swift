import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession plan is in its life cycle.
    enum AccessionPlanStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One accession plan, with what the planners need to act on it.
    final class AccessionPlan {
        var code: String
        var title: String
        var diagnosisCode: String
        var timezone: String
        var clinicianID: String
        var threshold: Double
        var dosageMg: Double
        var refills: Int
        var status: AccessionPlanStatus

        init(code: String, title: String, diagnosisCode: String, timezone: String, clinicianID: String, threshold: Double, dosageMg: Double, refills: Int, status: AccessionPlanStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.timezone = timezone
            self.clinicianID = clinicianID
            self.threshold = threshold
            self.dosageMg = dosageMg
            self.refills = refills
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

        func canMoveTo(_ next: AccessionPlanStatus) -> Bool {
            switch status {
            case .requested:
                return next == AccessionPlanStatus.granted
            case .granted:
                return next == AccessionPlanStatus.revoked || next == AccessionPlanStatus.expired
            case .revoked:
                return next == AccessionPlanStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("accession plan") \(code)"
        }

        func effectiveLoad() -> Double {
            return (threshold * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> AccessionPlan {
            return AccessionPlan(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                timezone: timezone,
                clinicianID: clinicianID,
                threshold: threshold,
                dosageMg: dosageMg,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a accession plan in status requested.
    static func newAccessionPlan(_ code: String, title: String) -> AccessionPlan {
        return AccessionPlan(
            code: code,
            title: title,
            diagnosisCode: "",
            timezone: "",
            clinicianID: "",
            threshold: 0.0,
            dosageMg: 0.0,
            refills: 0,
            status: AccessionPlanStatus.requested
        )
    }
}
