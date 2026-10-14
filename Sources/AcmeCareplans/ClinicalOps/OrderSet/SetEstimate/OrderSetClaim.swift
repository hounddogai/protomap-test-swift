import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set claim is in its life cycle.
    enum OrderSetClaimStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One order set claim, with what the planners need to act on it.
    final class OrderSetClaim {
        var code: String
        var name: String
        var capacity: Int
        var payer: String
        var label: String
        var attributes: [String: String]
        var bed: String
        var version: Int
        var encounterID: String
        var channel: String
        var status: OrderSetClaimStatus

        init(code: String, name: String, capacity: Int, payer: String, label: String, attributes: [String: String], bed: String, version: Int, encounterID: String, channel: String, status: OrderSetClaimStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.payer = payer
            self.label = label
            self.attributes = attributes
            self.bed = bed
            self.version = version
            self.encounterID = encounterID
            self.channel = channel
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OrderSetClaimStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == OrderSetClaimStatus.completed
            case .inProgress:
                return next == OrderSetClaimStatus.completed
            case .completed:
                return next == OrderSetClaimStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OrderSetClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
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

        func adjustedTotal() -> Double {
            return ((Double(capacity) - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetClaim {
            return OrderSetClaim(
                code: code,
                name: name,
                capacity: capacity,
                payer: payer,
                label: label,
                attributes: attributes,
                bed: bed,
                version: version,
                encounterID: encounterID,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a order set claim in status planned.
    static func newOrderSetClaim(_ code: String, name: String) -> OrderSetClaim {
        return OrderSetClaim(
            code: code,
            name: name,
            capacity: 0,
            payer: "",
            label: "",
            attributes: [:],
            bed: "",
            version: 0,
            encounterID: "",
            channel: "",
            status: OrderSetClaimStatus.planned
        )
    }
}
