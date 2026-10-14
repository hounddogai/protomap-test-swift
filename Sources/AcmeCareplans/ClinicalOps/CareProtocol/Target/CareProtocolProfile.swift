import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol profile is in its life cycle.
    enum CareProtocolProfileStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A care protocol profile. Its code is unique within a tenant.
    final class CareProtocolProfile {
        var code: String
        var label: String
        var approved: Bool
        var active: Bool
        var channel: String
        var score: Double
        var status: CareProtocolProfileStatus

        init(code: String, label: String, approved: Bool, active: Bool, channel: String, score: Double, status: CareProtocolProfileStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.active = active
            self.channel = channel
            self.score = score
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

        func canMoveTo(_ next: CareProtocolProfileStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == CareProtocolProfileStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("care protocol profile") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> CareProtocolProfile {
            return CareProtocolProfile(
                code: code,
                label: label,
                approved: approved,
                active: active,
                channel: channel,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a care protocol profile in status planned.
    static func newCareProtocolProfile(_ code: String, label: String) -> CareProtocolProfile {
        return CareProtocolProfile(
            code: code,
            label: label,
            approved: false,
            active: false,
            channel: "",
            score: 0.0,
            status: CareProtocolProfileStatus.planned
        )
    }
}
