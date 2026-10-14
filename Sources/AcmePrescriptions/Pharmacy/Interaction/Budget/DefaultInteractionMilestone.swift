import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a default interaction milestone is in its life cycle.
    enum DefaultInteractionMilestoneStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One default interaction milestone, with what the planners need to act on it.
    final class DefaultInteractionMilestone {
        var code: String
        var label: String
        var createdAt: Int
        var visitMinutes: Int
        var pinned: Bool
        var segment: String
        var priority: Int
        var summary: String
        var batchSize: Int
        var version: Int
        var status: DefaultInteractionMilestoneStatus

        init(code: String, label: String, createdAt: Int, visitMinutes: Int, pinned: Bool, segment: String, priority: Int, summary: String, batchSize: Int, version: Int, status: DefaultInteractionMilestoneStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.visitMinutes = visitMinutes
            self.pinned = pinned
            self.segment = segment
            self.priority = priority
            self.summary = summary
            self.batchSize = batchSize
            self.version = version
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

        func canMoveTo(_ next: DefaultInteractionMilestoneStatus) -> Bool {
            switch status {
            case .`open`:
                return next == DefaultInteractionMilestoneStatus.resolved
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DefaultInteractionMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default interaction milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\("default interaction milestone") \(code)"
        }

        func netExposure() -> Double {
            return (Double(version) * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> DefaultInteractionMilestone {
            return DefaultInteractionMilestone(
                code: code,
                label: label,
                createdAt: createdAt,
                visitMinutes: visitMinutes,
                pinned: pinned,
                segment: segment,
                priority: priority,
                summary: summary,
                batchSize: batchSize,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a default interaction milestone in status open.
    static func newDefaultInteractionMilestone(_ code: String, label: String) -> DefaultInteractionMilestone {
        return DefaultInteractionMilestone(
            code: code,
            label: label,
            createdAt: 0,
            visitMinutes: 0,
            pinned: false,
            segment: "",
            priority: 0,
            summary: "",
            batchSize: 0,
            version: 0,
            status: DefaultInteractionMilestoneStatus.`open`
        )
    }
}
