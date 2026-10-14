import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory window is in its life cycle.
    enum InventoryWindowStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One inventory window, with what the planners need to act on it.
    final class InventoryWindow {
        var code: String
        var title: String
        var description: String
        var active: Bool
        var externalRef: String
        var payer: String
        var source: String
        var weight: Double
        var status: InventoryWindowStatus

        init(code: String, title: String, description: String, active: Bool, externalRef: String, payer: String, source: String, weight: Double, status: InventoryWindowStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.active = active
            self.externalRef = externalRef
            self.payer = payer
            self.source = source
            self.weight = weight
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: InventoryWindowStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: InventoryWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return weight
        }

        func copyValue() -> InventoryWindow {
            return InventoryWindow(
                code: code,
                title: title,
                description: description,
                active: active,
                externalRef: externalRef,
                payer: payer,
                source: source,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a inventory window in status new.
    static func newInventoryWindow(_ code: String, title: String) -> InventoryWindow {
        return InventoryWindow(
            code: code,
            title: title,
            description: "",
            active: false,
            externalRef: "",
            payer: "",
            source: "",
            weight: 0.0,
            status: InventoryWindowStatus.new
        )
    }
}
