import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning notice is in its life cycle.
    enum CleaningNoticeStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A cleaning notice. Its code is unique within a tenant.
    final class CleaningNotice {
        var code: String
        var label: String
        var minimum: Double
        var weight: Double
        var channel: String
        var clinicianID: String
        var attempts: Int
        var status: CleaningNoticeStatus

        init(code: String, label: String, minimum: Double, weight: Double, channel: String, clinicianID: String, attempts: Int, status: CleaningNoticeStatus) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.weight = weight
            self.channel = channel
            self.clinicianID = clinicianID
            self.attempts = attempts
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

        func canMoveTo(_ next: CleaningNoticeStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == CleaningNoticeStatus.done
            case .running:
                return next == CleaningNoticeStatus.done || next == CleaningNoticeStatus.failed
            case .done:
                return next == CleaningNoticeStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CleaningNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveLoad() -> Double {
            return ((weight + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> CleaningNotice {
            return CleaningNotice(
                code: code,
                label: label,
                minimum: minimum,
                weight: weight,
                channel: channel,
                clinicianID: clinicianID,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a cleaning notice in status new.
    static func newCleaningNotice(_ code: String, label: String) -> CleaningNotice {
        return CleaningNotice(
            code: code,
            label: label,
            minimum: 0.0,
            weight: 0.0,
            channel: "",
            clinicianID: "",
            attempts: 0,
            status: CleaningNoticeStatus.new
        )
    }
}
