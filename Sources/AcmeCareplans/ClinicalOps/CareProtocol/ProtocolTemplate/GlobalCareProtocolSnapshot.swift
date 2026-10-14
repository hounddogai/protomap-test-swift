import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a global care protocol snapshot is in its life cycle.
    enum GlobalCareProtocolSnapshotStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a global care protocol snapshot and its current status.
    final class GlobalCareProtocolSnapshot {
        var code: String
        var name: String
        var capacity: Int
        var checksum: String
        var region: String
        var endsAt: Int
        var reviewer: String
        var priority: Int
        var status: GlobalCareProtocolSnapshotStatus

        init(code: String, name: String, capacity: Int, checksum: String, region: String, endsAt: Int, reviewer: String, priority: Int, status: GlobalCareProtocolSnapshotStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.checksum = checksum
            self.region = region
            self.endsAt = endsAt
            self.reviewer = reviewer
            self.priority = priority
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

        func canMoveTo(_ next: GlobalCareProtocolSnapshotStatus) -> Bool {
            switch status {
            case .requested:
                return next == GlobalCareProtocolSnapshotStatus.revoked || next == GlobalCareProtocolSnapshotStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: GlobalCareProtocolSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global care protocol snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveLoad() -> Double {
            return (Double(priority) * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> GlobalCareProtocolSnapshot {
            return GlobalCareProtocolSnapshot(
                code: code,
                name: name,
                capacity: capacity,
                checksum: checksum,
                region: region,
                endsAt: endsAt,
                reviewer: reviewer,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a global care protocol snapshot in status requested.
    static func newGlobalCareProtocolSnapshot(_ code: String, name: String) -> GlobalCareProtocolSnapshot {
        return GlobalCareProtocolSnapshot(
            code: code,
            name: name,
            capacity: 0,
            checksum: "",
            region: "",
            endsAt: 0,
            reviewer: "",
            priority: 0,
            status: GlobalCareProtocolSnapshotStatus.requested
        )
    }
}
