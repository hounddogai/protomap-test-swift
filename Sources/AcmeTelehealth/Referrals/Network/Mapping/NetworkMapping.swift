import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network mapping is in its life cycle.
    enum NetworkMappingStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A network mapping. Its code is unique within a tenant.
    final class NetworkMapping {
        var code: String
        var name: String
        var label: String
        var title: String
        var notes: String
        var amount: Double
        var status: NetworkMappingStatus

        init(code: String, name: String, label: String, title: String, notes: String, amount: Double, status: NetworkMappingStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.title = title
            self.notes = notes
            self.amount = amount
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

        func canMoveTo(_ next: NetworkMappingStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == NetworkMappingStatus.withdrawn
            case .rejected:
                return next == NetworkMappingStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: NetworkMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> NetworkMapping {
            return NetworkMapping(
                code: code,
                name: name,
                label: label,
                title: title,
                notes: notes,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a network mapping in status proposed.
    static func newNetworkMapping(_ code: String, name: String) -> NetworkMapping {
        return NetworkMapping(
            code: code,
            name: name,
            label: "",
            title: "",
            notes: "",
            amount: 0.0,
            status: NetworkMappingStatus.proposed
        )
    }
}
