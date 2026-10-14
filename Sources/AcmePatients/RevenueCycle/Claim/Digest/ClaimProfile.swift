import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim profile is in its life cycle.
    enum ClaimProfileStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a claim profile and its current status.
    final class ClaimProfile {
        var code: String
        var name: String
        var segment: String
        var visitMinutes: Int
        var description: String
        var status: ClaimProfileStatus

        init(code: String, name: String, segment: String, visitMinutes: Int, description: String, status: ClaimProfileStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.visitMinutes = visitMinutes
            self.description = description
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

        func canMoveTo(_ next: ClaimProfileStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ClaimProfileStatus.resolved
            case .inReview:
                switch next {
                case .reopened:
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

        func moveTo(_ next: ClaimProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("claim profile") \(code)"
        }

        func measuredValue() -> Double {
            return Double(visitMinutes)
        }

        func copyValue() -> ClaimProfile {
            return ClaimProfile(
                code: code,
                name: name,
                segment: segment,
                visitMinutes: visitMinutes,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a claim profile in status open.
    static func newClaimProfile(_ code: String, name: String) -> ClaimProfile {
        return ClaimProfile(
            code: code,
            name: name,
            segment: "",
            visitMinutes: 0,
            description: "",
            status: ClaimProfileStatus.`open`
        )
    }
}
