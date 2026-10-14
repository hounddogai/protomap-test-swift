import AcmePlatform
import Foundation

extension Staffing {
    /// Where a capped shift snapshot is in its life cycle.
    enum CappedShiftSnapshotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A capped shift snapshot as the shift team keeps it.
    final class CappedShiftSnapshot {
        var code: String
        var label: String
        var floorValue: Double
        var source: String
        var revision: Int
        var currency: String
        var summary: String
        var retries: Int
        var status: CappedShiftSnapshotStatus

        init(code: String, label: String, floorValue: Double, source: String, revision: Int, currency: String, summary: String, retries: Int, status: CappedShiftSnapshotStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.source = source
            self.revision = revision
            self.currency = currency
            self.summary = summary
            self.retries = retries
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedShiftSnapshotStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == CappedShiftSnapshotStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: CappedShiftSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped shift snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("capped shift snapshot") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((Double(retries) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> CappedShiftSnapshot {
            return CappedShiftSnapshot(
                code: code,
                label: label,
                floorValue: floorValue,
                source: source,
                revision: revision,
                currency: currency,
                summary: summary,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a capped shift snapshot in status created.
    static func newCappedShiftSnapshot(_ code: String, label: String) -> CappedShiftSnapshot {
        return CappedShiftSnapshot(
            code: code,
            label: label,
            floorValue: 0.0,
            source: "",
            revision: 0,
            currency: "",
            summary: "",
            retries: 0,
            status: CappedShiftSnapshotStatus.created
        )
    }
}
