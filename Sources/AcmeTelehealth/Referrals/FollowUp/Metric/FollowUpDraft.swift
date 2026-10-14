import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up draft is in its life cycle.
    enum FollowUpDraftStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One follow up draft, with what the planners need to act on it.
    final class FollowUpDraft {
        var code: String
        var label: String
        var score: Double
        var unit: String
        var payer: String
        var contactEmail: String
        var ceiling: Double
        var status: FollowUpDraftStatus

        init(code: String, label: String, score: Double, unit: String, payer: String, contactEmail: String, ceiling: Double, status: FollowUpDraftStatus) {
            self.code = code
            self.label = label
            self.score = score
            self.unit = unit
            self.payer = payer
            self.contactEmail = contactEmail
            self.ceiling = ceiling
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

        func canMoveTo(_ next: FollowUpDraftStatus) -> Bool {
            switch status {
            case .idle:
                return next == FollowUpDraftStatus.warming || next == FollowUpDraftStatus.ready
            case .warming:
                return next == FollowUpDraftStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == FollowUpDraftStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("follow up draft") \(code)"
        }

        func netValue() -> Double {
            return (ceiling * score * 100).rounded() / 100
        }

        func copyValue() -> FollowUpDraft {
            return FollowUpDraft(
                code: code,
                label: label,
                score: score,
                unit: unit,
                payer: payer,
                contactEmail: contactEmail,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a follow up draft in status idle.
    static func newFollowUpDraft(_ code: String, label: String) -> FollowUpDraft {
        return FollowUpDraft(
            code: code,
            label: label,
            score: 0.0,
            unit: "",
            payer: "",
            contactEmail: "",
            ceiling: 0.0,
            status: FollowUpDraftStatus.idle
        )
    }
}
