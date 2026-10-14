import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a tiered recall metric is in its life cycle.
    enum TieredRecallMetricStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a tiered recall metric and its current status.
    final class TieredRecallMetric {
        var code: String
        var name: String
        var limit: Int
        var approved: Bool
        var segment: String
        var bed: String
        var status: TieredRecallMetricStatus

        init(code: String, name: String, limit: Int, approved: Bool, segment: String, bed: String, status: TieredRecallMetricStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.approved = approved
            self.segment = segment
            self.bed = bed
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

        func canMoveTo(_ next: TieredRecallMetricStatus) -> Bool {
            switch status {
            case .created:
                return next == TieredRecallMetricStatus.retired
            case .validated:
                return next == TieredRecallMetricStatus.published || next == TieredRecallMetricStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: TieredRecallMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered recall metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(limit)
        }

        func copyValue() -> TieredRecallMetric {
            return TieredRecallMetric(
                code: code,
                name: name,
                limit: limit,
                approved: approved,
                segment: segment,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a tiered recall metric in status created.
    static func newTieredRecallMetric(_ code: String, name: String) -> TieredRecallMetric {
        return TieredRecallMetric(
            code: code,
            name: name,
            limit: 0,
            approved: false,
            segment: "",
            bed: "",
            status: TieredRecallMetricStatus.created
        )
    }
}
