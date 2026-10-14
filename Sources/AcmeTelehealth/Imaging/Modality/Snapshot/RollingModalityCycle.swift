import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling modality cycle is in its life cycle.
    enum RollingModalityCycleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One rolling modality cycle, with what the planners need to act on it.
    final class RollingModalityCycle {
        var code: String
        var name: String
        var patientRef: String
        var notes: String
        var ratio: Double
        var version: Int
        var revision: Int
        var visible: Bool
        var limit: Int
        var status: RollingModalityCycleStatus

        init(code: String, name: String, patientRef: String, notes: String, ratio: Double, version: Int, revision: Int, visible: Bool, limit: Int, status: RollingModalityCycleStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.notes = notes
            self.ratio = ratio
            self.version = version
            self.revision = revision
            self.visible = visible
            self.limit = limit
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

        func canMoveTo(_ next: RollingModalityCycleStatus) -> Bool {
            switch status {
            case .draft:
                return next == RollingModalityCycleStatus.pending
            case .pending:
                return next == RollingModalityCycleStatus.active
            case .active:
                return next == RollingModalityCycleStatus.suspended || next == RollingModalityCycleStatus.closed
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

        func moveTo(_ next: RollingModalityCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling modality cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedValue() -> Double {
            return ((Double(limit) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> RollingModalityCycle {
            return RollingModalityCycle(
                code: code,
                name: name,
                patientRef: patientRef,
                notes: notes,
                ratio: ratio,
                version: version,
                revision: revision,
                visible: visible,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling modality cycle in status draft.
    static func newRollingModalityCycle(_ code: String, name: String) -> RollingModalityCycle {
        return RollingModalityCycle(
            code: code,
            name: name,
            patientRef: "",
            notes: "",
            ratio: 0.0,
            version: 0,
            revision: 0,
            visible: false,
            limit: 0,
            status: RollingModalityCycleStatus.draft
        )
    }
}
