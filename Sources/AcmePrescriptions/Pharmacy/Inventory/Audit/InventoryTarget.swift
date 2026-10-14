import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory target is in its life cycle.
    enum InventoryTargetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A inventory target. Its code is unique within a tenant.
    final class InventoryTarget {
        var code: String
        var name: String
        var tags: [String]
        var durationMinutes: Int
        var revision: Int
        var ratio: Double
        var windowDays: Int
        var version: Int
        var minimum: Double
        var batchSize: Int
        var visible: Bool
        var status: InventoryTargetStatus

        init(code: String, name: String, tags: [String], durationMinutes: Int, revision: Int, ratio: Double, windowDays: Int, version: Int, minimum: Double, batchSize: Int, visible: Bool, status: InventoryTargetStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.durationMinutes = durationMinutes
            self.revision = revision
            self.ratio = ratio
            self.windowDays = windowDays
            self.version = version
            self.minimum = minimum
            self.batchSize = batchSize
            self.visible = visible
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

        func canMoveTo(_ next: InventoryTargetStatus) -> Bool {
            switch status {
            case .requested:
                return next == InventoryTargetStatus.revoked || next == InventoryTargetStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == InventoryTargetStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InventoryTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("inventory target") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedLoad() -> Double {
            return (Double(version) * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> InventoryTarget {
            return InventoryTarget(
                code: code,
                name: name,
                tags: tags,
                durationMinutes: durationMinutes,
                revision: revision,
                ratio: ratio,
                windowDays: windowDays,
                version: version,
                minimum: minimum,
                batchSize: batchSize,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a inventory target in status requested.
    static func newInventoryTarget(_ code: String, name: String) -> InventoryTarget {
        return InventoryTarget(
            code: code,
            name: name,
            tags: [],
            durationMinutes: 0,
            revision: 0,
            ratio: 0.0,
            windowDays: 0,
            version: 0,
            minimum: 0.0,
            batchSize: 0,
            visible: false,
            status: InventoryTargetStatus.requested
        )
    }
}
