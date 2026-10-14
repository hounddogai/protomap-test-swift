import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched statement group is in its life cycle.
    enum BatchedStatementGroupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A batched statement group as the statement team keeps it.
    final class BatchedStatementGroup {
        var code: String
        var title: String
        var visible: Bool
        var attempts: Int
        var description: String
        var payer: String
        var windowDays: Int
        var archived: Bool
        var timezone: String
        var approved: Bool
        var facility: String
        var status: BatchedStatementGroupStatus

        init(code: String, title: String, visible: Bool, attempts: Int, description: String, payer: String, windowDays: Int, archived: Bool, timezone: String, approved: Bool, facility: String, status: BatchedStatementGroupStatus) {
            self.code = code
            self.title = title
            self.visible = visible
            self.attempts = attempts
            self.description = description
            self.payer = payer
            self.windowDays = windowDays
            self.archived = archived
            self.timezone = timezone
            self.approved = approved
            self.facility = facility
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

        func canMoveTo(_ next: BatchedStatementGroupStatus) -> Bool {
            switch status {
            case .`open`:
                return next == BatchedStatementGroupStatus.archived
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == BatchedStatementGroupStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedStatementGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched statement group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedVolume() -> Double {
            return (Double(attempts) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> BatchedStatementGroup {
            return BatchedStatementGroup(
                code: code,
                title: title,
                visible: visible,
                attempts: attempts,
                description: description,
                payer: payer,
                windowDays: windowDays,
                archived: archived,
                timezone: timezone,
                approved: approved,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a batched statement group in status open.
    static func newBatchedStatementGroup(_ code: String, title: String) -> BatchedStatementGroup {
        return BatchedStatementGroup(
            code: code,
            title: title,
            visible: false,
            attempts: 0,
            description: "",
            payer: "",
            windowDays: 0,
            archived: false,
            timezone: "",
            approved: false,
            facility: "",
            status: BatchedStatementGroupStatus.`open`
        )
    }
}
