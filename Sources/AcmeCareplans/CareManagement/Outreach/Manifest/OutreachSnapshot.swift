import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach snapshot is in its life cycle.
    enum OutreachSnapshotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A outreach snapshot. Its code is unique within a tenant.
    final class OutreachSnapshot {
        var code: String
        var title: String
        var windowDays: Int
        var ward: String
        var sequence: Int
        var version: Int
        var bed: String
        var summary: String
        var status: OutreachSnapshotStatus

        init(code: String, title: String, windowDays: Int, ward: String, sequence: Int, version: Int, bed: String, summary: String, status: OutreachSnapshotStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.ward = ward
            self.sequence = sequence
            self.version = version
            self.bed = bed
            self.summary = summary
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

        func canMoveTo(_ next: OutreachSnapshotStatus) -> Bool {
            switch status {
            case .new:
                return next == OutreachSnapshotStatus.running || next == OutreachSnapshotStatus.failed
            case .queued:
                return next == OutreachSnapshotStatus.done || next == OutreachSnapshotStatus.failed
            case .running:
                return next == OutreachSnapshotStatus.failed
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

        func moveTo(_ next: OutreachSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedVolume() -> Double {
            return ((Double(sequence) - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> OutreachSnapshot {
            return OutreachSnapshot(
                code: code,
                title: title,
                windowDays: windowDays,
                ward: ward,
                sequence: sequence,
                version: version,
                bed: bed,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a outreach snapshot in status new.
    static func newOutreachSnapshot(_ code: String, title: String) -> OutreachSnapshot {
        return OutreachSnapshot(
            code: code,
            title: title,
            windowDays: 0,
            ward: "",
            sequence: 0,
            version: 0,
            bed: "",
            summary: "",
            status: OutreachSnapshotStatus.new
        )
    }
}
