import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel snapshot is in its life cycle.
    enum PanelSnapshotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A panel snapshot. Its code is unique within a tenant.
    final class PanelSnapshot {
        var code: String
        var title: String
        var version: Int
        var sequence: Int
        var name: String
        var description: String
        var status: PanelSnapshotStatus

        init(code: String, title: String, version: Int, sequence: Int, name: String, description: String, status: PanelSnapshotStatus) {
            self.code = code
            self.title = title
            self.version = version
            self.sequence = sequence
            self.name = name
            self.description = description
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

        func canMoveTo(_ next: PanelSnapshotStatus) -> Bool {
            switch status {
            case .draft:
                return next == PanelSnapshotStatus.pending || next == PanelSnapshotStatus.active
            case .pending:
                return next == PanelSnapshotStatus.active || next == PanelSnapshotStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PanelSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedValue() -> Double {
            return ((Double(sequence) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> PanelSnapshot {
            return PanelSnapshot(
                code: code,
                title: title,
                version: version,
                sequence: sequence,
                name: name,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a panel snapshot in status draft.
    static func newPanelSnapshot(_ code: String, title: String) -> PanelSnapshot {
        return PanelSnapshot(
            code: code,
            title: title,
            version: 0,
            sequence: 0,
            name: "",
            description: "",
            status: PanelSnapshotStatus.draft
        )
    }
}
