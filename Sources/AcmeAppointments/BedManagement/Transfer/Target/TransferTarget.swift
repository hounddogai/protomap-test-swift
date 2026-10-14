import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer target is in its life cycle.
    enum TransferTargetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One transfer target, with what the planners need to act on it.
    final class TransferTarget {
        var code: String
        var name: String
        var weight: Double
        var attributes: [String: String]
        var active: Bool
        var channel: String
        var minimum: Double
        var encounterID: String
        var status: TransferTargetStatus

        init(code: String, name: String, weight: Double, attributes: [String: String], active: Bool, channel: String, minimum: Double, encounterID: String, status: TransferTargetStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.attributes = attributes
            self.active = active
            self.channel = channel
            self.minimum = minimum
            self.encounterID = encounterID
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

        func canMoveTo(_ next: TransferTargetStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
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

        func moveTo(_ next: TransferTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("transfer target") \(code)"
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

        func netValue() -> Double {
            return ((weight - minimum) * 100).rounded() / 100
        }

        func copyValue() -> TransferTarget {
            return TransferTarget(
                code: code,
                name: name,
                weight: weight,
                attributes: attributes,
                active: active,
                channel: channel,
                minimum: minimum,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a transfer target in status requested.
    static func newTransferTarget(_ code: String, name: String) -> TransferTarget {
        return TransferTarget(
            code: code,
            name: name,
            weight: 0.0,
            attributes: [:],
            active: false,
            channel: "",
            minimum: 0.0,
            encounterID: "",
            status: TransferTargetStatus.requested
        )
    }
}
