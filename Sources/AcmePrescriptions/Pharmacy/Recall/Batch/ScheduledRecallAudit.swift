import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a scheduled recall audit is in its life cycle.
    enum ScheduledRecallAuditStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A scheduled recall audit. Its code is unique within a tenant.
    final class ScheduledRecallAudit {
        var code: String
        var label: String
        var durationMinutes: Int
        var minimum: Double
        var allergy: String
        var archived: Bool
        var score: Double
        var windowDays: Int
        var status: ScheduledRecallAuditStatus

        init(code: String, label: String, durationMinutes: Int, minimum: Double, allergy: String, archived: Bool, score: Double, windowDays: Int, status: ScheduledRecallAuditStatus) {
            self.code = code
            self.label = label
            self.durationMinutes = durationMinutes
            self.minimum = minimum
            self.allergy = allergy
            self.archived = archived
            self.score = score
            self.windowDays = windowDays
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

        func canMoveTo(_ next: ScheduledRecallAuditStatus) -> Bool {
            switch status {
            case .idle:
                return next == ScheduledRecallAuditStatus.stopped
            case .warming:
                return next == ScheduledRecallAuditStatus.draining
            case .ready:
                return next == ScheduledRecallAuditStatus.draining || next == ScheduledRecallAuditStatus.stopped
            case .draining:
                return next == ScheduledRecallAuditStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledRecallAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled recall audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netValue() -> Double {
            return ((score - minimum) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledRecallAudit {
            return ScheduledRecallAudit(
                code: code,
                label: label,
                durationMinutes: durationMinutes,
                minimum: minimum,
                allergy: allergy,
                archived: archived,
                score: score,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled recall audit in status idle.
    static func newScheduledRecallAudit(_ code: String, label: String) -> ScheduledRecallAudit {
        return ScheduledRecallAudit(
            code: code,
            label: label,
            durationMinutes: 0,
            minimum: 0.0,
            allergy: "",
            archived: false,
            score: 0.0,
            windowDays: 0,
            status: ScheduledRecallAuditStatus.idle
        )
    }
}
