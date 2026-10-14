import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a fallback assessment milestone is in its life cycle.
    enum FallbackAssessmentMilestoneStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One fallback assessment milestone, with what the planners need to act on it.
    final class FallbackAssessmentMilestone {
        var code: String
        var name: String
        var region: String
        var createdAt: Int
        var expiresAt: Int
        var channel: String
        var minimum: Double
        var summary: String
        var patientRef: String
        var facility: String
        var status: FallbackAssessmentMilestoneStatus

        init(code: String, name: String, region: String, createdAt: Int, expiresAt: Int, channel: String, minimum: Double, summary: String, patientRef: String, facility: String, status: FallbackAssessmentMilestoneStatus) {
            self.code = code
            self.name = name
            self.region = region
            self.createdAt = createdAt
            self.expiresAt = expiresAt
            self.channel = channel
            self.minimum = minimum
            self.summary = summary
            self.patientRef = patientRef
            self.facility = facility
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

        func canMoveTo(_ next: FallbackAssessmentMilestoneStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == FallbackAssessmentMilestoneStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackAssessmentMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback assessment milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("fallback assessment milestone") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(expiresAt) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackAssessmentMilestone {
            return FallbackAssessmentMilestone(
                code: code,
                name: name,
                region: region,
                createdAt: createdAt,
                expiresAt: expiresAt,
                channel: channel,
                minimum: minimum,
                summary: summary,
                patientRef: patientRef,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a fallback assessment milestone in status proposed.
    static func newFallbackAssessmentMilestone(_ code: String, name: String) -> FallbackAssessmentMilestone {
        return FallbackAssessmentMilestone(
            code: code,
            name: name,
            region: "",
            createdAt: 0,
            expiresAt: 0,
            channel: "",
            minimum: 0.0,
            summary: "",
            patientRef: "",
            facility: "",
            status: FallbackAssessmentMilestoneStatus.proposed
        )
    }
}
