import AcmePlatform
import Foundation

extension Referrals {
    /// Where a scheduled follow up draft is in its life cycle.
    enum ScheduledFollowUpDraftStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A scheduled follow up draft as the follow up team keeps it.
    final class ScheduledFollowUpDraft {
        var code: String
        var label: String
        var limit: Int
        var expiresAt: Int
        var approved: Bool
        var discount: Double
        var externalRef: String
        var status: ScheduledFollowUpDraftStatus

        init(code: String, label: String, limit: Int, expiresAt: Int, approved: Bool, discount: Double, externalRef: String, status: ScheduledFollowUpDraftStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.expiresAt = expiresAt
            self.approved = approved
            self.discount = discount
            self.externalRef = externalRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledFollowUpDraftStatus) -> Bool {
            switch status {
            case .new:
                return next == ScheduledFollowUpDraftStatus.running
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == ScheduledFollowUpDraftStatus.done
            case .done:
                return next == ScheduledFollowUpDraftStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledFollowUpDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled follow up draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("scheduled follow up draft") \(code)"
        }

        func netValue() -> Double {
            return ((discount + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledFollowUpDraft {
            return ScheduledFollowUpDraft(
                code: code,
                label: label,
                limit: limit,
                expiresAt: expiresAt,
                approved: approved,
                discount: discount,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled follow up draft in status new.
    static func newScheduledFollowUpDraft(_ code: String, label: String) -> ScheduledFollowUpDraft {
        return ScheduledFollowUpDraft(
            code: code,
            label: label,
            limit: 0,
            expiresAt: 0,
            approved: false,
            discount: 0.0,
            externalRef: "",
            status: ScheduledFollowUpDraftStatus.new
        )
    }
}
