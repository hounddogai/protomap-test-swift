import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility request is in its life cycle.
    enum EligibilityRequestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A eligibility request as the eligibility team keeps it.
    final class EligibilityRequest {
        var code: String
        var title: String
        var channel: String
        var notes: String
        var ownerID: String
        var name: String
        var description: String
        var quantity: Int
        var status: EligibilityRequestStatus

        init(code: String, title: String, channel: String, notes: String, ownerID: String, name: String, description: String, quantity: Int, status: EligibilityRequestStatus) {
            self.code = code
            self.title = title
            self.channel = channel
            self.notes = notes
            self.ownerID = ownerID
            self.name = name
            self.description = description
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: EligibilityRequestStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == EligibilityRequestStatus.completed || next == EligibilityRequestStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: EligibilityRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> EligibilityRequest {
            return EligibilityRequest(
                code: code,
                title: title,
                channel: channel,
                notes: notes,
                ownerID: ownerID,
                name: name,
                description: description,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a eligibility request in status planned.
    static func newEligibilityRequest(_ code: String, title: String) -> EligibilityRequest {
        return EligibilityRequest(
            code: code,
            title: title,
            channel: "",
            notes: "",
            ownerID: "",
            name: "",
            description: "",
            quantity: 0,
            status: EligibilityRequestStatus.planned
        )
    }
}
