import AcmePlatform
import Foundation

extension Staffing {
    /// Where a scheduled float pool audit is in its life cycle.
    enum ScheduledFloatPoolAuditStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A scheduled float pool audit as the float pool team keeps it.
    final class ScheduledFloatPoolAudit {
        var code: String
        var label: String
        var payer: String
        var channel: String
        var name: String
        var attributes: [String: String]
        var quantity: Int
        var status: ScheduledFloatPoolAuditStatus

        init(code: String, label: String, payer: String, channel: String, name: String, attributes: [String: String], quantity: Int, status: ScheduledFloatPoolAuditStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.channel = channel
            self.name = name
            self.attributes = attributes
            self.quantity = quantity
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

        func canMoveTo(_ next: ScheduledFloatPoolAuditStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ScheduledFloatPoolAuditStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledFloatPoolAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled float pool audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
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

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> ScheduledFloatPoolAudit {
            return ScheduledFloatPoolAudit(
                code: code,
                label: label,
                payer: payer,
                channel: channel,
                name: name,
                attributes: attributes,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a scheduled float pool audit in status requested.
    static func newScheduledFloatPoolAudit(_ code: String, label: String) -> ScheduledFloatPoolAudit {
        return ScheduledFloatPoolAudit(
            code: code,
            label: label,
            payer: "",
            channel: "",
            name: "",
            attributes: [:],
            quantity: 0,
            status: ScheduledFloatPoolAuditStatus.requested
        )
    }
}
