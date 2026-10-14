import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted interaction tier is in its life cycle.
    enum WeightedInteractionTierStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A weighted interaction tier as the interaction team keeps it.
    final class WeightedInteractionTier {
        var code: String
        var label: String
        var sequence: Int
        var unit: String
        var ownerID: String
        var channel: String
        var priority: Int
        var minimum: Double
        var retries: Int
        var ratio: Double
        var status: WeightedInteractionTierStatus

        init(code: String, label: String, sequence: Int, unit: String, ownerID: String, channel: String, priority: Int, minimum: Double, retries: Int, ratio: Double, status: WeightedInteractionTierStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.unit = unit
            self.ownerID = ownerID
            self.channel = channel
            self.priority = priority
            self.minimum = minimum
            self.retries = retries
            self.ratio = ratio
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedInteractionTierStatus) -> Bool {
            switch status {
            case .idle:
                return next == WeightedInteractionTierStatus.draining
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == WeightedInteractionTierStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedInteractionTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted interaction tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedValue() -> Double {
            return ((Double(sequence) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> WeightedInteractionTier {
            return WeightedInteractionTier(
                code: code,
                label: label,
                sequence: sequence,
                unit: unit,
                ownerID: ownerID,
                channel: channel,
                priority: priority,
                minimum: minimum,
                retries: retries,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a weighted interaction tier in status idle.
    static func newWeightedInteractionTier(_ code: String, label: String) -> WeightedInteractionTier {
        return WeightedInteractionTier(
            code: code,
            label: label,
            sequence: 0,
            unit: "",
            ownerID: "",
            channel: "",
            priority: 0,
            minimum: 0.0,
            retries: 0,
            ratio: 0.0,
            status: WeightedInteractionTierStatus.idle
        )
    }
}
