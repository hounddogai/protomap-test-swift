import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a scheduled assessment digest is in its life cycle.
    enum ScheduledAssessmentDigestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A scheduled assessment digest. Its code is unique within a tenant.
    final class ScheduledAssessmentDigest {
        var code: String
        var title: String
        var limit: Int
        var allergy: String
        var clinicianID: String
        var budget: Double
        var source: String
        var status: ScheduledAssessmentDigestStatus

        init(code: String, title: String, limit: Int, allergy: String, clinicianID: String, budget: Double, source: String, status: ScheduledAssessmentDigestStatus) {
            self.code = code
            self.title = title
            self.limit = limit
            self.allergy = allergy
            self.clinicianID = clinicianID
            self.budget = budget
            self.source = source
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

        func canMoveTo(_ next: ScheduledAssessmentDigestStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == ScheduledAssessmentDigestStatus.expired
            case .revoked:
                return next == ScheduledAssessmentDigestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledAssessmentDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled assessment digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled assessment digest") \(code)"
        }

        func projectedLoad() -> Double {
            return ((Double(limit) + budget) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledAssessmentDigest {
            return ScheduledAssessmentDigest(
                code: code,
                title: title,
                limit: limit,
                allergy: allergy,
                clinicianID: clinicianID,
                budget: budget,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a scheduled assessment digest in status requested.
    static func newScheduledAssessmentDigest(_ code: String, title: String) -> ScheduledAssessmentDigest {
        return ScheduledAssessmentDigest(
            code: code,
            title: title,
            limit: 0,
            allergy: "",
            clinicianID: "",
            budget: 0.0,
            source: "",
            status: ScheduledAssessmentDigestStatus.requested
        )
    }
}
