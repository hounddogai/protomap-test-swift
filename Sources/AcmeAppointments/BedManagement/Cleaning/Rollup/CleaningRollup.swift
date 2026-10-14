import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning rollup is in its life cycle.
    enum CleaningRollupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One cleaning rollup, with what the planners need to act on it.
    final class CleaningRollup {
        var code: String
        var label: String
        var channel: String
        var visitMinutes: Int
        var reviewer: String
        var status: CleaningRollupStatus

        init(code: String, label: String, channel: String, visitMinutes: Int, reviewer: String, status: CleaningRollupStatus) {
            self.code = code
            self.label = label
            self.channel = channel
            self.visitMinutes = visitMinutes
            self.reviewer = reviewer
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

        func canMoveTo(_ next: CleaningRollupStatus) -> Bool {
            switch status {
            case .new:
                return next == CleaningRollupStatus.queued
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == CleaningRollupStatus.done || next == CleaningRollupStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: CleaningRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return Double(visitMinutes)
        }

        func copyValue() -> CleaningRollup {
            return CleaningRollup(
                code: code,
                label: label,
                channel: channel,
                visitMinutes: visitMinutes,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a cleaning rollup in status new.
    static func newCleaningRollup(_ code: String, label: String) -> CleaningRollup {
        return CleaningRollup(
            code: code,
            label: label,
            channel: "",
            visitMinutes: 0,
            reviewer: "",
            status: CleaningRollupStatus.new
        )
    }
}
