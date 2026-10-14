import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert snapshot is in its life cycle.
    enum AlertSnapshotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a alert snapshot and its current status.
    final class AlertSnapshot {
        var code: String
        var label: String
        var summary: String
        var sequence: Int
        var unit: String
        var version: Int
        var status: AlertSnapshotStatus

        init(code: String, label: String, summary: String, sequence: Int, unit: String, version: Int, status: AlertSnapshotStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.sequence = sequence
            self.unit = unit
            self.version = version
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

        func canMoveTo(_ next: AlertSnapshotStatus) -> Bool {
            switch status {
            case .draft:
                return next == AlertSnapshotStatus.suspended
            case .pending:
                return next == AlertSnapshotStatus.active
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == AlertSnapshotStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AlertSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedVolume() -> Double {
            return ((Double(sequence) - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> AlertSnapshot {
            return AlertSnapshot(
                code: code,
                label: label,
                summary: summary,
                sequence: sequence,
                unit: unit,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a alert snapshot in status draft.
    static func newAlertSnapshot(_ code: String, label: String) -> AlertSnapshot {
        return AlertSnapshot(
            code: code,
            label: label,
            summary: "",
            sequence: 0,
            unit: "",
            version: 0,
            status: AlertSnapshotStatus.draft
        )
    }
}
