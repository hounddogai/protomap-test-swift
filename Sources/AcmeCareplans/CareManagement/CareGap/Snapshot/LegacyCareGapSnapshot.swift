import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a legacy care gap snapshot is in its life cycle.
    enum LegacyCareGapSnapshotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A legacy care gap snapshot. Its code is unique within a tenant.
    final class LegacyCareGapSnapshot {
        var code: String
        var label: String
        var phone: String
        var durationMinutes: Int
        var attempts: Int
        var floorValue: Double
        var channel: String
        var status: LegacyCareGapSnapshotStatus

        init(code: String, label: String, phone: String, durationMinutes: Int, attempts: Int, floorValue: Double, channel: String, status: LegacyCareGapSnapshotStatus) {
            self.code = code
            self.label = label
            self.phone = phone
            self.durationMinutes = durationMinutes
            self.attempts = attempts
            self.floorValue = floorValue
            self.channel = channel
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyCareGapSnapshotStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == LegacyCareGapSnapshotStatus.closed
            case .active:
                return next == LegacyCareGapSnapshotStatus.suspended || next == LegacyCareGapSnapshotStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: LegacyCareGapSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy care gap snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedExposure() -> Double {
            return (Double(attempts) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> LegacyCareGapSnapshot {
            return LegacyCareGapSnapshot(
                code: code,
                label: label,
                phone: phone,
                durationMinutes: durationMinutes,
                attempts: attempts,
                floorValue: floorValue,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a legacy care gap snapshot in status draft.
    static func newLegacyCareGapSnapshot(_ code: String, label: String) -> LegacyCareGapSnapshot {
        return LegacyCareGapSnapshot(
            code: code,
            label: label,
            phone: "",
            durationMinutes: 0,
            attempts: 0,
            floorValue: 0.0,
            channel: "",
            status: LegacyCareGapSnapshotStatus.draft
        )
    }
}
