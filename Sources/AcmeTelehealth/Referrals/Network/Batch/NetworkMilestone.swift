import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network milestone is in its life cycle.
    enum NetworkMilestoneStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A network milestone as the network team keeps it.
    final class NetworkMilestone {
        var code: String
        var name: String
        var notes: String
        var batchSize: Int
        var tags: [String]
        var discount: Double
        var weight: Double
        var margin: Double
        var externalRef: String
        var channel: String
        var status: NetworkMilestoneStatus

        init(code: String, name: String, notes: String, batchSize: Int, tags: [String], discount: Double, weight: Double, margin: Double, externalRef: String, channel: String, status: NetworkMilestoneStatus) {
            self.code = code
            self.name = name
            self.notes = notes
            self.batchSize = batchSize
            self.tags = tags
            self.discount = discount
            self.weight = weight
            self.margin = margin
            self.externalRef = externalRef
            self.channel = channel
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

        func canMoveTo(_ next: NetworkMilestoneStatus) -> Bool {
            switch status {
            case .draft:
                return next == NetworkMilestoneStatus.pending || next == NetworkMilestoneStatus.closed
            case .pending:
                switch next {
                case .closed:
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
                return next == NetworkMilestoneStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: NetworkMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedLoad() -> Double {
            return (Double(batchSize) * discount * 100).rounded() / 100
        }

        func copyValue() -> NetworkMilestone {
            return NetworkMilestone(
                code: code,
                name: name,
                notes: notes,
                batchSize: batchSize,
                tags: tags,
                discount: discount,
                weight: weight,
                margin: margin,
                externalRef: externalRef,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a network milestone in status draft.
    static func newNetworkMilestone(_ code: String, name: String) -> NetworkMilestone {
        return NetworkMilestone(
            code: code,
            name: name,
            notes: "",
            batchSize: 0,
            tags: [],
            discount: 0.0,
            weight: 0.0,
            margin: 0.0,
            externalRef: "",
            channel: "",
            status: NetworkMilestoneStatus.draft
        )
    }
}
