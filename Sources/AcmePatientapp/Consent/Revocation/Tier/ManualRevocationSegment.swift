import AcmePlatform
import Foundation

extension Consent {
    /// Where a manual revocation segment is in its life cycle.
    enum ManualRevocationSegmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a manual revocation segment and its current status.
    final class ManualRevocationSegment {
        var code: String
        var name: String
        var windowDays: Int
        var batchSize: Int
        var summary: String
        var active: Bool
        var bed: String
        var timezone: String
        var encounterID: String
        var status: ManualRevocationSegmentStatus

        init(code: String, name: String, windowDays: Int, batchSize: Int, summary: String, active: Bool, bed: String, timezone: String, encounterID: String, status: ManualRevocationSegmentStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.batchSize = batchSize
            self.summary = summary
            self.active = active
            self.bed = bed
            self.timezone = timezone
            self.encounterID = encounterID
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

        func canMoveTo(_ next: ManualRevocationSegmentStatus) -> Bool {
            switch status {
            case .planned:
                return next == ManualRevocationSegmentStatus.inProgress || next == ManualRevocationSegmentStatus.completed
            case .scheduled:
                return next == ManualRevocationSegmentStatus.completed || next == ManualRevocationSegmentStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ManualRevocationSegmentStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualRevocationSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual revocation segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedExposure() -> Double {
            return (Double(windowDays) * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> ManualRevocationSegment {
            return ManualRevocationSegment(
                code: code,
                name: name,
                windowDays: windowDays,
                batchSize: batchSize,
                summary: summary,
                active: active,
                bed: bed,
                timezone: timezone,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual revocation segment in status planned.
    static func newManualRevocationSegment(_ code: String, name: String) -> ManualRevocationSegment {
        return ManualRevocationSegment(
            code: code,
            name: name,
            windowDays: 0,
            batchSize: 0,
            summary: "",
            active: false,
            bed: "",
            timezone: "",
            encounterID: "",
            status: ManualRevocationSegmentStatus.planned
        )
    }
}
