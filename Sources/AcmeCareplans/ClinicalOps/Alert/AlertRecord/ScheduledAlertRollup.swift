import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a scheduled alert rollup is in its life cycle.
    enum ScheduledAlertRollupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a scheduled alert rollup and its current status.
    final class ScheduledAlertRollup {
        var code: String
        var name: String
        var label: String
        var ward: String
        var attempts: Int
        var title: String
        var channel: String
        var active: Bool
        var minimum: Double
        var status: ScheduledAlertRollupStatus

        init(code: String, name: String, label: String, ward: String, attempts: Int, title: String, channel: String, active: Bool, minimum: Double, status: ScheduledAlertRollupStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.ward = ward
            self.attempts = attempts
            self.title = title
            self.channel = channel
            self.active = active
            self.minimum = minimum
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

        func canMoveTo(_ next: ScheduledAlertRollupStatus) -> Bool {
            switch status {
            case .new:
                return next == ScheduledAlertRollupStatus.queued || next == ScheduledAlertRollupStatus.done
            case .queued:
                return next == ScheduledAlertRollupStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ScheduledAlertRollupStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledAlertRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled alert rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func projectedValue() -> Double {
            return ((Double(attempts) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledAlertRollup {
            return ScheduledAlertRollup(
                code: code,
                name: name,
                label: label,
                ward: ward,
                attempts: attempts,
                title: title,
                channel: channel,
                active: active,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a scheduled alert rollup in status new.
    static func newScheduledAlertRollup(_ code: String, name: String) -> ScheduledAlertRollup {
        return ScheduledAlertRollup(
            code: code,
            name: name,
            label: "",
            ward: "",
            attempts: 0,
            title: "",
            channel: "",
            active: false,
            minimum: 0.0,
            status: ScheduledAlertRollupStatus.new
        )
    }
}
