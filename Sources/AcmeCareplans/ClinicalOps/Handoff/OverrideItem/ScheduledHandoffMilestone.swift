import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a scheduled handoff milestone is in its life cycle.
    enum ScheduledHandoffMilestoneStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a scheduled handoff milestone and its current status.
    final class ScheduledHandoffMilestone {
        var code: String
        var label: String
        var contactEmail: String
        var timezone: String
        var approved: Bool
        var version: Int
        var description: String
        var country: String
        var threshold: Double
        var notes: String
        var status: ScheduledHandoffMilestoneStatus

        init(code: String, label: String, contactEmail: String, timezone: String, approved: Bool, version: Int, description: String, country: String, threshold: Double, notes: String, status: ScheduledHandoffMilestoneStatus) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.timezone = timezone
            self.approved = approved
            self.version = version
            self.description = description
            self.country = country
            self.threshold = threshold
            self.notes = notes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledHandoffMilestoneStatus) -> Bool {
            switch status {
            case .idle:
                return next == ScheduledHandoffMilestoneStatus.warming || next == ScheduledHandoffMilestoneStatus.stopped
            case .warming:
                return next == ScheduledHandoffMilestoneStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ScheduledHandoffMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled handoff milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("scheduled handoff milestone") \(code)"
        }

        func adjustedTotal() -> Double {
            return (Double(version) * threshold * 100).rounded() / 100
        }

        func copyValue() -> ScheduledHandoffMilestone {
            return ScheduledHandoffMilestone(
                code: code,
                label: label,
                contactEmail: contactEmail,
                timezone: timezone,
                approved: approved,
                version: version,
                description: description,
                country: country,
                threshold: threshold,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a scheduled handoff milestone in status idle.
    static func newScheduledHandoffMilestone(_ code: String, label: String) -> ScheduledHandoffMilestone {
        return ScheduledHandoffMilestone(
            code: code,
            label: label,
            contactEmail: "",
            timezone: "",
            approved: false,
            version: 0,
            description: "",
            country: "",
            threshold: 0.0,
            notes: "",
            status: ScheduledHandoffMilestoneStatus.idle
        )
    }
}
