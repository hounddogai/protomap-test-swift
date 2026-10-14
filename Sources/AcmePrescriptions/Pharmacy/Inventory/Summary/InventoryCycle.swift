import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory cycle is in its life cycle.
    enum InventoryCycleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One inventory cycle, with what the planners need to act on it.
    final class InventoryCycle {
        var code: String
        var title: String
        var batchSize: Int
        var updatedAt: Int
        var version: Int
        var patientRef: String
        var status: InventoryCycleStatus

        init(code: String, title: String, batchSize: Int, updatedAt: Int, version: Int, patientRef: String, status: InventoryCycleStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.updatedAt = updatedAt
            self.version = version
            self.patientRef = patientRef
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

        func canMoveTo(_ next: InventoryCycleStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == InventoryCycleStatus.revoked || next == InventoryCycleStatus.expired
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

        func moveTo(_ next: InventoryCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\("inventory cycle") \(code)"
        }

        func effectiveValue() -> Double {
            return (Double(batchSize) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> InventoryCycle {
            return InventoryCycle(
                code: code,
                title: title,
                batchSize: batchSize,
                updatedAt: updatedAt,
                version: version,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a inventory cycle in status requested.
    static func newInventoryCycle(_ code: String, title: String) -> InventoryCycle {
        return InventoryCycle(
            code: code,
            title: title,
            batchSize: 0,
            updatedAt: 0,
            version: 0,
            patientRef: "",
            status: InventoryCycleStatus.requested
        )
    }
}
