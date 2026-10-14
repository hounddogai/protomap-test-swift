import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding profile is in its life cycle.
    enum RoundingProfileStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A rounding profile. Its code is unique within a tenant.
    final class RoundingProfile {
        var code: String
        var name: String
        var channel: String
        var threshold: Double
        var country: String
        var maximum: Double
        var status: RoundingProfileStatus

        init(code: String, name: String, channel: String, threshold: Double, country: String, maximum: Double, status: RoundingProfileStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.threshold = threshold
            self.country = country
            self.maximum = maximum
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

        func canMoveTo(_ next: RoundingProfileStatus) -> Bool {
            switch status {
            case .planned:
                return next == RoundingProfileStatus.scheduled || next == RoundingProfileStatus.completed
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == RoundingProfileStatus.cancelled
            case .completed:
                return next == RoundingProfileStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RoundingProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveLoad() -> Double {
            return (threshold * maximum * 100).rounded() / 100
        }

        func copyValue() -> RoundingProfile {
            return RoundingProfile(
                code: code,
                name: name,
                channel: channel,
                threshold: threshold,
                country: country,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a rounding profile in status planned.
    static func newRoundingProfile(_ code: String, name: String) -> RoundingProfile {
        return RoundingProfile(
            code: code,
            name: name,
            channel: "",
            threshold: 0.0,
            country: "",
            maximum: 0.0,
            status: RoundingProfileStatus.planned
        )
    }
}
