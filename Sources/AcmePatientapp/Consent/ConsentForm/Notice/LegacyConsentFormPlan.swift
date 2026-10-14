import AcmePlatform
import Foundation

extension Consent {
    /// Where a legacy consent form plan is in its life cycle.
    enum LegacyConsentFormPlanStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A legacy consent form plan as the consent form team keeps it.
    final class LegacyConsentFormPlan {
        var code: String
        var title: String
        var retries: Int
        var facility: String
        var refills: Int
        var sequence: Int
        var timezone: String
        var expiresAt: Int
        var archived: Bool
        var minimum: Double
        var status: LegacyConsentFormPlanStatus

        init(code: String, title: String, retries: Int, facility: String, refills: Int, sequence: Int, timezone: String, expiresAt: Int, archived: Bool, minimum: Double, status: LegacyConsentFormPlanStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.facility = facility
            self.refills = refills
            self.sequence = sequence
            self.timezone = timezone
            self.expiresAt = expiresAt
            self.archived = archived
            self.minimum = minimum
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

        func canMoveTo(_ next: LegacyConsentFormPlanStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LegacyConsentFormPlanStatus.reopened
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == LegacyConsentFormPlanStatus.reopened || next == LegacyConsentFormPlanStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: LegacyConsentFormPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy consent form plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedLoad() -> Double {
            return ((Double(sequence) - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyConsentFormPlan {
            return LegacyConsentFormPlan(
                code: code,
                title: title,
                retries: retries,
                facility: facility,
                refills: refills,
                sequence: sequence,
                timezone: timezone,
                expiresAt: expiresAt,
                archived: archived,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a legacy consent form plan in status open.
    static func newLegacyConsentFormPlan(_ code: String, title: String) -> LegacyConsentFormPlan {
        return LegacyConsentFormPlan(
            code: code,
            title: title,
            retries: 0,
            facility: "",
            refills: 0,
            sequence: 0,
            timezone: "",
            expiresAt: 0,
            archived: false,
            minimum: 0.0,
            status: LegacyConsentFormPlanStatus.`open`
        )
    }
}
