import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility group is in its life cycle.
    enum EligibilityGroupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A eligibility group as the eligibility team keeps it.
    final class EligibilityGroup {
        var code: String
        var title: String
        var summary: String
        var diagnosisCode: String
        var specialty: String
        var procedureCode: String
        var unit: String
        var attempts: Int
        var graceDays: Int
        var endsAt: Int
        var status: EligibilityGroupStatus

        init(code: String, title: String, summary: String, diagnosisCode: String, specialty: String, procedureCode: String, unit: String, attempts: Int, graceDays: Int, endsAt: Int, status: EligibilityGroupStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.diagnosisCode = diagnosisCode
            self.specialty = specialty
            self.procedureCode = procedureCode
            self.unit = unit
            self.attempts = attempts
            self.graceDays = graceDays
            self.endsAt = endsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: EligibilityGroupStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == EligibilityGroupStatus.reopened || next == EligibilityGroupStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == EligibilityGroupStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilityGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("eligibility group") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((Double(graceDays) - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityGroup {
            return EligibilityGroup(
                code: code,
                title: title,
                summary: summary,
                diagnosisCode: diagnosisCode,
                specialty: specialty,
                procedureCode: procedureCode,
                unit: unit,
                attempts: attempts,
                graceDays: graceDays,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a eligibility group in status open.
    static func newEligibilityGroup(_ code: String, title: String) -> EligibilityGroup {
        return EligibilityGroup(
            code: code,
            title: title,
            summary: "",
            diagnosisCode: "",
            specialty: "",
            procedureCode: "",
            unit: "",
            attempts: 0,
            graceDays: 0,
            endsAt: 0,
            status: EligibilityGroupStatus.`open`
        )
    }
}
