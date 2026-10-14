import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning snapshot is in its life cycle.
    enum CleaningSnapshotStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A cleaning snapshot. Its code is unique within a tenant.
    final class CleaningSnapshot {
        var code: String
        var name: String
        var title: String
        var payer: String
        var ratio: Double
        var segment: String
        var status: CleaningSnapshotStatus

        init(code: String, name: String, title: String, payer: String, ratio: Double, segment: String, status: CleaningSnapshotStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.payer = payer
            self.ratio = ratio
            self.segment = segment
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CleaningSnapshotStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == CleaningSnapshotStatus.revoked
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: CleaningSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return ratio
        }

        func copyValue() -> CleaningSnapshot {
            return CleaningSnapshot(
                code: code,
                name: name,
                title: title,
                payer: payer,
                ratio: ratio,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a cleaning snapshot in status requested.
    static func newCleaningSnapshot(_ code: String, name: String) -> CleaningSnapshot {
        return CleaningSnapshot(
            code: code,
            name: name,
            title: "",
            payer: "",
            ratio: 0.0,
            segment: "",
            status: CleaningSnapshotStatus.requested
        )
    }
}
