import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist target is in its life cycle.
    enum WorklistTargetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A worklist target. Its code is unique within a tenant.
    final class WorklistTarget {
        var code: String
        var title: String
        var channel: String
        var capacity: Int
        var visitMinutes: Int
        var phone: String
        var ceiling: Double
        var status: WorklistTargetStatus

        init(code: String, title: String, channel: String, capacity: Int, visitMinutes: Int, phone: String, ceiling: Double, status: WorklistTargetStatus) {
            self.code = code
            self.title = title
            self.channel = channel
            self.capacity = capacity
            self.visitMinutes = visitMinutes
            self.phone = phone
            self.ceiling = ceiling
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

        func canMoveTo(_ next: WorklistTargetStatus) -> Bool {
            switch status {
            case .`open`:
                return next == WorklistTargetStatus.inReview || next == WorklistTargetStatus.reopened
            case .inReview:
                return next == WorklistTargetStatus.reopened
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == WorklistTargetStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WorklistTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("worklist target") \(code)"
        }

        func weightedTotal() -> Double {
            return (Double(capacity) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> WorklistTarget {
            return WorklistTarget(
                code: code,
                title: title,
                channel: channel,
                capacity: capacity,
                visitMinutes: visitMinutes,
                phone: phone,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a worklist target in status open.
    static func newWorklistTarget(_ code: String, title: String) -> WorklistTarget {
        return WorklistTarget(
            code: code,
            title: title,
            channel: "",
            capacity: 0,
            visitMinutes: 0,
            phone: "",
            ceiling: 0.0,
            status: WorklistTargetStatus.`open`
        )
    }
}
