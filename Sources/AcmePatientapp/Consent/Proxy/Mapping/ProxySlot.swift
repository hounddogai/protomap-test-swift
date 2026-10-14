import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy slot is in its life cycle.
    enum ProxySlotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A proxy slot as the proxy team keeps it.
    final class ProxySlot {
        var code: String
        var label: String
        var dosageMg: Double
        var graceDays: Int
        var active: Bool
        var visible: Bool
        var version: Int
        var attributes: [String: String]
        var status: ProxySlotStatus

        init(code: String, label: String, dosageMg: Double, graceDays: Int, active: Bool, visible: Bool, version: Int, attributes: [String: String], status: ProxySlotStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.graceDays = graceDays
            self.active = active
            self.visible = visible
            self.version = version
            self.attributes = attributes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ProxySlotStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ProxySlotStatus.rejected || next == ProxySlotStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: ProxySlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("proxy slot") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func netExposure() -> Double {
            return ((Double(version) - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> ProxySlot {
            return ProxySlot(
                code: code,
                label: label,
                dosageMg: dosageMg,
                graceDays: graceDays,
                active: active,
                visible: visible,
                version: version,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a proxy slot in status proposed.
    static func newProxySlot(_ code: String, label: String) -> ProxySlot {
        return ProxySlot(
            code: code,
            label: label,
            dosageMg: 0.0,
            graceDays: 0,
            active: false,
            visible: false,
            version: 0,
            attributes: [:],
            status: ProxySlotStatus.proposed
        )
    }
}
