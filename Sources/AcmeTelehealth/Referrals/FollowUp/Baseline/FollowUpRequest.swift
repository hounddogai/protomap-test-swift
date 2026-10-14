import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up request is in its life cycle.
    enum FollowUpRequestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One follow up request, with what the planners need to act on it.
    final class FollowUpRequest {
        var code: String
        var title: String
        var encounterID: String
        var endsAt: Int
        var payer: String
        var description: String
        var contactEmail: String
        var status: FollowUpRequestStatus

        init(code: String, title: String, encounterID: String, endsAt: Int, payer: String, description: String, contactEmail: String, status: FollowUpRequestStatus) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.endsAt = endsAt
            self.payer = payer
            self.description = description
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: FollowUpRequestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == FollowUpRequestStatus.running
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == FollowUpRequestStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return Double(endsAt)
        }

        func copyValue() -> FollowUpRequest {
            return FollowUpRequest(
                code: code,
                title: title,
                encounterID: encounterID,
                endsAt: endsAt,
                payer: payer,
                description: description,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a follow up request in status new.
    static func newFollowUpRequest(_ code: String, title: String) -> FollowUpRequest {
        return FollowUpRequest(
            code: code,
            title: title,
            encounterID: "",
            endsAt: 0,
            payer: "",
            description: "",
            contactEmail: "",
            status: FollowUpRequestStatus.new
        )
    }
}
