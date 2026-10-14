import AcmePlatform
import Foundation

extension Imaging {
    /// Where a pending priority metric is in its life cycle.
    enum PendingPriorityMetricStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A pending priority metric as the priority team keeps it.
    final class PendingPriorityMetric {
        var code: String
        var title: String
        var unit: String
        var batchSize: Int
        var discount: Double
        var attributes: [String: String]
        var sequence: Int
        var channel: String
        var revision: Int
        var status: PendingPriorityMetricStatus

        init(code: String, title: String, unit: String, batchSize: Int, discount: Double, attributes: [String: String], sequence: Int, channel: String, revision: Int, status: PendingPriorityMetricStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.batchSize = batchSize
            self.discount = discount
            self.attributes = attributes
            self.sequence = sequence
            self.channel = channel
            self.revision = revision
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingPriorityMetricStatus) -> Bool {
            switch status {
            case .new:
                return next == PendingPriorityMetricStatus.failed
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == PendingPriorityMetricStatus.failed
            case .done:
                return next == PendingPriorityMetricStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingPriorityMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending priority metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
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

        func projectedLoad() -> Double {
            return ((Double(batchSize) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> PendingPriorityMetric {
            return PendingPriorityMetric(
                code: code,
                title: title,
                unit: unit,
                batchSize: batchSize,
                discount: discount,
                attributes: attributes,
                sequence: sequence,
                channel: channel,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a pending priority metric in status new.
    static func newPendingPriorityMetric(_ code: String, title: String) -> PendingPriorityMetric {
        return PendingPriorityMetric(
            code: code,
            title: title,
            unit: "",
            batchSize: 0,
            discount: 0.0,
            attributes: [:],
            sequence: 0,
            channel: "",
            revision: 0,
            status: PendingPriorityMetricStatus.new
        )
    }
}
