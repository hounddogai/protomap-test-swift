import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol milestone is in its life cycle.
    enum CareProtocolMilestoneStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a care protocol milestone and its current status.
    final class CareProtocolMilestone {
        var code: String
        var title: String
        var notes: String
        var payer: String
        var attempts: Int
        var active: Bool
        var visitMinutes: Int
        var status: CareProtocolMilestoneStatus

        init(code: String, title: String, notes: String, payer: String, attempts: Int, active: Bool, visitMinutes: Int, status: CareProtocolMilestoneStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.payer = payer
            self.attempts = attempts
            self.active = active
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: CareProtocolMilestoneStatus) -> Bool {
            switch status {
            case .`open`:
                return next == CareProtocolMilestoneStatus.archived
            case .inReview:
                switch next {
                case .resolved:
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

        func moveTo(_ next: CareProtocolMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("care protocol milestone") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(visitMinutes) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolMilestone {
            return CareProtocolMilestone(
                code: code,
                title: title,
                notes: notes,
                payer: payer,
                attempts: attempts,
                active: active,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a care protocol milestone in status open.
    static func newCareProtocolMilestone(_ code: String, title: String) -> CareProtocolMilestone {
        return CareProtocolMilestone(
            code: code,
            title: title,
            notes: "",
            payer: "",
            attempts: 0,
            active: false,
            visitMinutes: 0,
            status: CareProtocolMilestoneStatus.`open`
        )
    }
}
