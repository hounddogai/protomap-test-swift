import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a adaptive outreach segment is in its life cycle.
    enum AdaptiveOutreachSegmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A adaptive outreach segment as the outreach team keeps it.
    final class AdaptiveOutreachSegment {
        var code: String
        var name: String
        var summary: String
        var active: Bool
        var contactEmail: String
        var priority: Int
        var refills: Int
        var procedureCode: String
        var acuity: Int
        var budget: Double
        var status: AdaptiveOutreachSegmentStatus

        init(code: String, name: String, summary: String, active: Bool, contactEmail: String, priority: Int, refills: Int, procedureCode: String, acuity: Int, budget: Double, status: AdaptiveOutreachSegmentStatus) {
            self.code = code
            self.name = name
            self.summary = summary
            self.active = active
            self.contactEmail = contactEmail
            self.priority = priority
            self.refills = refills
            self.procedureCode = procedureCode
            self.acuity = acuity
            self.budget = budget
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

        func canMoveTo(_ next: AdaptiveOutreachSegmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AdaptiveOutreachSegmentStatus.withdrawn
            case .approved:
                return next == AdaptiveOutreachSegmentStatus.withdrawn
            case .rejected:
                return next == AdaptiveOutreachSegmentStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveOutreachSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive outreach segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive outreach segment") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((Double(acuity) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveOutreachSegment {
            return AdaptiveOutreachSegment(
                code: code,
                name: name,
                summary: summary,
                active: active,
                contactEmail: contactEmail,
                priority: priority,
                refills: refills,
                procedureCode: procedureCode,
                acuity: acuity,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive outreach segment in status proposed.
    static func newAdaptiveOutreachSegment(_ code: String, name: String) -> AdaptiveOutreachSegment {
        return AdaptiveOutreachSegment(
            code: code,
            name: name,
            summary: "",
            active: false,
            contactEmail: "",
            priority: 0,
            refills: 0,
            procedureCode: "",
            acuity: 0,
            budget: 0.0,
            status: AdaptiveOutreachSegmentStatus.proposed
        )
    }
}
