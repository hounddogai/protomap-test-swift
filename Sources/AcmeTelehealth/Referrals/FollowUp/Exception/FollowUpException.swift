import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up exception is in its life cycle.
    enum FollowUpExceptionStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a follow up exception and its current status.
    final class FollowUpException {
        var code: String
        var label: String
        var channel: String
        var limit: Int
        var copay: Double
        var source: String
        var checksum: String
        var name: String
        var floorValue: Double
        var status: FollowUpExceptionStatus

        init(code: String, label: String, channel: String, limit: Int, copay: Double, source: String, checksum: String, name: String, floorValue: Double, status: FollowUpExceptionStatus) {
            self.code = code
            self.label = label
            self.channel = channel
            self.limit = limit
            self.copay = copay
            self.source = source
            self.checksum = checksum
            self.name = name
            self.floorValue = floorValue
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

        func canMoveTo(_ next: FollowUpExceptionStatus) -> Bool {
            switch status {
            case .`open`:
                return next == FollowUpExceptionStatus.resolved || next == FollowUpExceptionStatus.reopened
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
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == FollowUpExceptionStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netExposure() -> Double {
            return ((Double(limit) - copay) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpException {
            return FollowUpException(
                code: code,
                label: label,
                channel: channel,
                limit: limit,
                copay: copay,
                source: source,
                checksum: checksum,
                name: name,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a follow up exception in status open.
    static func newFollowUpException(_ code: String, label: String) -> FollowUpException {
        return FollowUpException(
            code: code,
            label: label,
            channel: "",
            limit: 0,
            copay: 0.0,
            source: "",
            checksum: "",
            name: "",
            floorValue: 0.0,
            status: FollowUpExceptionStatus.`open`
        )
    }
}
