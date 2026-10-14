import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory manifest is in its life cycle.
    enum InventoryManifestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A inventory manifest. Its code is unique within a tenant.
    final class InventoryManifest {
        var code: String
        var title: String
        var source: String
        var refills: Int
        var capacity: Int
        var reviewer: String
        var checksum: String
        var status: InventoryManifestStatus

        init(code: String, title: String, source: String, refills: Int, capacity: Int, reviewer: String, checksum: String, status: InventoryManifestStatus) {
            self.code = code
            self.title = title
            self.source = source
            self.refills = refills
            self.capacity = capacity
            self.reviewer = reviewer
            self.checksum = checksum
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

        func canMoveTo(_ next: InventoryManifestStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == InventoryManifestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InventoryManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedTotal() -> Double {
            return ((Double(capacity) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> InventoryManifest {
            return InventoryManifest(
                code: code,
                title: title,
                source: source,
                refills: refills,
                capacity: capacity,
                reviewer: reviewer,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a inventory manifest in status requested.
    static func newInventoryManifest(_ code: String, title: String) -> InventoryManifest {
        return InventoryManifest(
            code: code,
            title: title,
            source: "",
            refills: 0,
            capacity: 0,
            reviewer: "",
            checksum: "",
            status: InventoryManifestStatus.requested
        )
    }
}
