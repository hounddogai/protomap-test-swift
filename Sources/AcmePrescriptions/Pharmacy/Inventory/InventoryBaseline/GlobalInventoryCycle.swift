import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a global inventory cycle is in its life cycle.
    enum GlobalInventoryCycleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A global inventory cycle as the inventory team keeps it.
    final class GlobalInventoryCycle {
        var code: String
        var name: String
        var quantity: Int
        var region: String
        var dosageMg: Double
        var channel: String
        var active: Bool
        var status: GlobalInventoryCycleStatus

        init(code: String, name: String, quantity: Int, region: String, dosageMg: Double, channel: String, active: Bool, status: GlobalInventoryCycleStatus) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.region = region
            self.dosageMg = dosageMg
            self.channel = channel
            self.active = active
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

        func canMoveTo(_ next: GlobalInventoryCycleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
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
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == GlobalInventoryCycleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalInventoryCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global inventory cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("global inventory cycle") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((Double(quantity) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> GlobalInventoryCycle {
            return GlobalInventoryCycle(
                code: code,
                name: name,
                quantity: quantity,
                region: region,
                dosageMg: dosageMg,
                channel: channel,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a global inventory cycle in status draft.
    static func newGlobalInventoryCycle(_ code: String, name: String) -> GlobalInventoryCycle {
        return GlobalInventoryCycle(
            code: code,
            name: name,
            quantity: 0,
            region: "",
            dosageMg: 0.0,
            channel: "",
            active: false,
            status: GlobalInventoryCycleStatus.draft
        )
    }
}
