import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a scheduled care protocol threshold is in its life cycle.
    enum ScheduledCareProtocolThresholdStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a scheduled care protocol threshold and its current status.
    final class ScheduledCareProtocolThreshold {
        var code: String
        var name: String
        var patientRef: String
        var attempts: Int
        var channel: String
        var status: ScheduledCareProtocolThresholdStatus

        init(code: String, name: String, patientRef: String, attempts: Int, channel: String, status: ScheduledCareProtocolThresholdStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.attempts = attempts
            self.channel = channel
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

        func canMoveTo(_ next: ScheduledCareProtocolThresholdStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ScheduledCareProtocolThresholdStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == ScheduledCareProtocolThresholdStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledCareProtocolThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled care protocol threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(attempts)
        }

        func copyValue() -> ScheduledCareProtocolThreshold {
            return ScheduledCareProtocolThreshold(
                code: code,
                name: name,
                patientRef: patientRef,
                attempts: attempts,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a scheduled care protocol threshold in status idle.
    static func newScheduledCareProtocolThreshold(_ code: String, name: String) -> ScheduledCareProtocolThreshold {
        return ScheduledCareProtocolThreshold(
            code: code,
            name: name,
            patientRef: "",
            attempts: 0,
            channel: "",
            status: ScheduledCareProtocolThresholdStatus.idle
        )
    }
}
