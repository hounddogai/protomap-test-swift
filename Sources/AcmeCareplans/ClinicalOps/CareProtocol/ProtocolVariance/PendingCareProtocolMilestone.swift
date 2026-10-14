import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a pending care protocol milestone is in its life cycle.
    enum PendingCareProtocolMilestoneStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A pending care protocol milestone. Its code is unique within a tenant.
    final class PendingCareProtocolMilestone {
        var code: String
        var name: String
        var sequence: Int
        var threshold: Double
        var budget: Double
        var windowDays: Int
        var externalRef: String
        var archived: Bool
        var createdAt: Int
        var timezone: String
        var status: PendingCareProtocolMilestoneStatus

        init(code: String, name: String, sequence: Int, threshold: Double, budget: Double, windowDays: Int, externalRef: String, archived: Bool, createdAt: Int, timezone: String, status: PendingCareProtocolMilestoneStatus) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.threshold = threshold
            self.budget = budget
            self.windowDays = windowDays
            self.externalRef = externalRef
            self.archived = archived
            self.createdAt = createdAt
            self.timezone = timezone
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

        func canMoveTo(_ next: PendingCareProtocolMilestoneStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == PendingCareProtocolMilestoneStatus.reopened || next == PendingCareProtocolMilestoneStatus.archived
            case .reopened:
                return next == PendingCareProtocolMilestoneStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingCareProtocolMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending care protocol milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("pending care protocol milestone") \(code)"
        }

        func netLoad() -> Double {
            return ((budget + threshold) * 100).rounded() / 100
        }

        func copyValue() -> PendingCareProtocolMilestone {
            return PendingCareProtocolMilestone(
                code: code,
                name: name,
                sequence: sequence,
                threshold: threshold,
                budget: budget,
                windowDays: windowDays,
                externalRef: externalRef,
                archived: archived,
                createdAt: createdAt,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending care protocol milestone in status open.
    static func newPendingCareProtocolMilestone(_ code: String, name: String) -> PendingCareProtocolMilestone {
        return PendingCareProtocolMilestone(
            code: code,
            name: name,
            sequence: 0,
            threshold: 0.0,
            budget: 0.0,
            windowDays: 0,
            externalRef: "",
            archived: false,
            createdAt: 0,
            timezone: "",
            status: PendingCareProtocolMilestoneStatus.`open`
        )
    }
}
