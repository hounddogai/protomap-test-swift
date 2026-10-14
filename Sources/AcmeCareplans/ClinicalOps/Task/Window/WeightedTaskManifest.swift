import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a weighted task manifest is in its life cycle.
    enum WeightedTaskManifestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One weighted task manifest, with what the planners need to act on it.
    final class WeightedTaskManifest {
        var code: String
        var title: String
        var ceiling: Double
        var sequence: Int
        var channel: String
        var quantity: Int
        var notes: String
        var threshold: Double
        var copay: Double
        var status: WeightedTaskManifestStatus

        init(code: String, title: String, ceiling: Double, sequence: Int, channel: String, quantity: Int, notes: String, threshold: Double, copay: Double, status: WeightedTaskManifestStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.sequence = sequence
            self.channel = channel
            self.quantity = quantity
            self.notes = notes
            self.threshold = threshold
            self.copay = copay
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

        func canMoveTo(_ next: WeightedTaskManifestStatus) -> Bool {
            switch status {
            case .created:
                return next == WeightedTaskManifestStatus.published || next == WeightedTaskManifestStatus.retired
            case .validated:
                return next == WeightedTaskManifestStatus.published
            case .published:
                return next == WeightedTaskManifestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedTaskManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted task manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("weighted task manifest") \(code)"
        }

        func weightedTotal() -> Double {
            return (copay * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> WeightedTaskManifest {
            return WeightedTaskManifest(
                code: code,
                title: title,
                ceiling: ceiling,
                sequence: sequence,
                channel: channel,
                quantity: quantity,
                notes: notes,
                threshold: threshold,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a weighted task manifest in status created.
    static func newWeightedTaskManifest(_ code: String, title: String) -> WeightedTaskManifest {
        return WeightedTaskManifest(
            code: code,
            title: title,
            ceiling: 0.0,
            sequence: 0,
            channel: "",
            quantity: 0,
            notes: "",
            threshold: 0.0,
            copay: 0.0,
            status: WeightedTaskManifestStatus.created
        )
    }
}
