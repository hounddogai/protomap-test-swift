import AcmePlatform
import Foundation

extension Referrals {
    /// Where a primary network tier is in its life cycle.
    enum PrimaryNetworkTierStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a primary network tier and its current status.
    final class PrimaryNetworkTier {
        var code: String
        var name: String
        var sequence: Int
        var capacity: Int
        var priority: Int
        var summary: String
        var status: PrimaryNetworkTierStatus

        init(code: String, name: String, sequence: Int, capacity: Int, priority: Int, summary: String, status: PrimaryNetworkTierStatus) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.capacity = capacity
            self.priority = priority
            self.summary = summary
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

        func canMoveTo(_ next: PrimaryNetworkTierStatus) -> Bool {
            switch status {
            case .created:
                return next == PrimaryNetworkTierStatus.validated || next == PrimaryNetworkTierStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == PrimaryNetworkTierStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryNetworkTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary network tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary network tier") \(code)"
        }

        func projectedLoad() -> Double {
            return ((Double(sequence) + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryNetworkTier {
            return PrimaryNetworkTier(
                code: code,
                name: name,
                sequence: sequence,
                capacity: capacity,
                priority: priority,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary network tier in status created.
    static func newPrimaryNetworkTier(_ code: String, name: String) -> PrimaryNetworkTier {
        return PrimaryNetworkTier(
            code: code,
            name: name,
            sequence: 0,
            capacity: 0,
            priority: 0,
            summary: "",
            status: PrimaryNetworkTierStatus.created
        )
    }
}
