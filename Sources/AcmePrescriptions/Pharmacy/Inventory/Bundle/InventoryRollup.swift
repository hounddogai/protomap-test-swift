import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory rollup is in its life cycle.
    enum InventoryRollupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One inventory rollup, with what the planners need to act on it.
    final class InventoryRollup {
        var code: String
        var name: String
        var floorValue: Double
        var ward: String
        var segment: String
        var endsAt: Int
        var dosageMg: Double
        var retries: Int
        var ceiling: Double
        var status: InventoryRollupStatus

        init(code: String, name: String, floorValue: Double, ward: String, segment: String, endsAt: Int, dosageMg: Double, retries: Int, ceiling: Double, status: InventoryRollupStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.ward = ward
            self.segment = segment
            self.endsAt = endsAt
            self.dosageMg = dosageMg
            self.retries = retries
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: InventoryRollupStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == InventoryRollupStatus.draining
            case .draining:
                return next == InventoryRollupStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InventoryRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedTotal() -> Double {
            return ((Double(retries) + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> InventoryRollup {
            return InventoryRollup(
                code: code,
                name: name,
                floorValue: floorValue,
                ward: ward,
                segment: segment,
                endsAt: endsAt,
                dosageMg: dosageMg,
                retries: retries,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a inventory rollup in status idle.
    static func newInventoryRollup(_ code: String, name: String) -> InventoryRollup {
        return InventoryRollup(
            code: code,
            name: name,
            floorValue: 0.0,
            ward: "",
            segment: "",
            endsAt: 0,
            dosageMg: 0.0,
            retries: 0,
            ceiling: 0.0,
            status: InventoryRollupStatus.idle
        )
    }
}
