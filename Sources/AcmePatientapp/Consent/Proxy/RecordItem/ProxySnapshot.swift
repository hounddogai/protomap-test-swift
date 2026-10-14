import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy snapshot is in its life cycle.
    enum ProxySnapshotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A proxy snapshot. Its code is unique within a tenant.
    final class ProxySnapshot {
        var code: String
        var name: String
        var visitMinutes: Int
        var durationMinutes: Int
        var clinicianID: String
        var status: ProxySnapshotStatus

        init(code: String, name: String, visitMinutes: Int, durationMinutes: Int, clinicianID: String, status: ProxySnapshotStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.durationMinutes = durationMinutes
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: ProxySnapshotStatus) -> Bool {
            switch status {
            case .draft:
                return next == ProxySnapshotStatus.pending || next == ProxySnapshotStatus.active
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
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

        func moveTo(_ next: ProxySnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netLoad() -> Double {
            return ((Double(durationMinutes) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ProxySnapshot {
            return ProxySnapshot(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                durationMinutes: durationMinutes,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a proxy snapshot in status draft.
    static func newProxySnapshot(_ code: String, name: String) -> ProxySnapshot {
        return ProxySnapshot(
            code: code,
            name: name,
            visitMinutes: 0,
            durationMinutes: 0,
            clinicianID: "",
            status: ProxySnapshotStatus.draft
        )
    }
}
