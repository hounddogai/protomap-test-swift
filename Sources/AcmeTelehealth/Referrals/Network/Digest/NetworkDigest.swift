import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network digest is in its life cycle.
    enum NetworkDigestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a network digest and its current status.
    final class NetworkDigest {
        var code: String
        var name: String
        var encounterID: String
        var bed: String
        var capacity: Int
        var status: NetworkDigestStatus

        init(code: String, name: String, encounterID: String, bed: String, capacity: Int, status: NetworkDigestStatus) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.bed = bed
            self.capacity = capacity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: NetworkDigestStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == NetworkDigestStatus.published || next == NetworkDigestStatus.retired
            case .published:
                return next == NetworkDigestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: NetworkDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(capacity)
        }

        func copyValue() -> NetworkDigest {
            return NetworkDigest(
                code: code,
                name: name,
                encounterID: encounterID,
                bed: bed,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a network digest in status created.
    static func newNetworkDigest(_ code: String, name: String) -> NetworkDigest {
        return NetworkDigest(
            code: code,
            name: name,
            encounterID: "",
            bed: "",
            capacity: 0,
            status: NetworkDigestStatus.created
        )
    }
}
