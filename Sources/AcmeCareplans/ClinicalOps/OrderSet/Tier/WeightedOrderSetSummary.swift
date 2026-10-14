import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a weighted order set summary is in its life cycle.
    enum WeightedOrderSetSummaryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A weighted order set summary. Its code is unique within a tenant.
    final class WeightedOrderSetSummary {
        var code: String
        var label: String
        var archived: Bool
        var visible: Bool
        var segment: String
        var limit: Int
        var version: Int
        var source: String
        var status: WeightedOrderSetSummaryStatus

        init(code: String, label: String, archived: Bool, visible: Bool, segment: String, limit: Int, version: Int, source: String, status: WeightedOrderSetSummaryStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.visible = visible
            self.segment = segment
            self.limit = limit
            self.version = version
            self.source = source
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

        func canMoveTo(_ next: WeightedOrderSetSummaryStatus) -> Bool {
            switch status {
            case .new:
                return next == WeightedOrderSetSummaryStatus.failed
            case .queued:
                return next == WeightedOrderSetSummaryStatus.running || next == WeightedOrderSetSummaryStatus.done
            case .running:
                return next == WeightedOrderSetSummaryStatus.done || next == WeightedOrderSetSummaryStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: WeightedOrderSetSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted order set summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("weighted order set summary") \(code)"
        }

        func projectedValue() -> Double {
            return (Double(limit) * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> WeightedOrderSetSummary {
            return WeightedOrderSetSummary(
                code: code,
                label: label,
                archived: archived,
                visible: visible,
                segment: segment,
                limit: limit,
                version: version,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a weighted order set summary in status new.
    static func newWeightedOrderSetSummary(_ code: String, label: String) -> WeightedOrderSetSummary {
        return WeightedOrderSetSummary(
            code: code,
            label: label,
            archived: false,
            visible: false,
            segment: "",
            limit: 0,
            version: 0,
            source: "",
            status: WeightedOrderSetSummaryStatus.new
        )
    }
}
