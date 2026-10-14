import AcmePlatform
import Foundation

extension Labs {
    /// Where a global reference range snapshot is in its life cycle.
    enum GlobalReferenceRangeSnapshotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One global reference range snapshot, with what the planners need to act on it.
    final class GlobalReferenceRangeSnapshot {
        var code: String
        var label: String
        var capacity: Int
        var checksum: String
        var rate: Double
        var copay: Double
        var windowDays: Int
        var clinicianID: String
        var status: GlobalReferenceRangeSnapshotStatus

        init(code: String, label: String, capacity: Int, checksum: String, rate: Double, copay: Double, windowDays: Int, clinicianID: String, status: GlobalReferenceRangeSnapshotStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.checksum = checksum
            self.rate = rate
            self.copay = copay
            self.windowDays = windowDays
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: GlobalReferenceRangeSnapshotStatus) -> Bool {
            switch status {
            case .new:
                return next == GlobalReferenceRangeSnapshotStatus.queued
            case .queued:
                return next == GlobalReferenceRangeSnapshotStatus.done || next == GlobalReferenceRangeSnapshotStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == GlobalReferenceRangeSnapshotStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalReferenceRangeSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global reference range snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("global reference range snapshot") \(code)"
        }

        func weightedTotal() -> Double {
            return ((rate - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalReferenceRangeSnapshot {
            return GlobalReferenceRangeSnapshot(
                code: code,
                label: label,
                capacity: capacity,
                checksum: checksum,
                rate: rate,
                copay: copay,
                windowDays: windowDays,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global reference range snapshot in status new.
    static func newGlobalReferenceRangeSnapshot(_ code: String, label: String) -> GlobalReferenceRangeSnapshot {
        return GlobalReferenceRangeSnapshot(
            code: code,
            label: label,
            capacity: 0,
            checksum: "",
            rate: 0.0,
            copay: 0.0,
            windowDays: 0,
            clinicianID: "",
            status: GlobalReferenceRangeSnapshotStatus.new
        )
    }
}
