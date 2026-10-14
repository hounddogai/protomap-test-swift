import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession metric is in its life cycle.
    enum AccessionMetricStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A accession metric. Its code is unique within a tenant.
    final class AccessionMetric {
        var code: String
        var title: String
        var notes: String
        var capacity: Int
        var bed: String
        var rate: Double
        var status: AccessionMetricStatus

        init(code: String, title: String, notes: String, capacity: Int, bed: String, rate: Double, status: AccessionMetricStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.capacity = capacity
            self.bed = bed
            self.rate = rate
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

        func canMoveTo(_ next: AccessionMetricStatus) -> Bool {
            switch status {
            case .planned:
                return next == AccessionMetricStatus.inProgress
            case .scheduled:
                return next == AccessionMetricStatus.inProgress
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == AccessionMetricStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedVolume() -> Double {
            return ((rate - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> AccessionMetric {
            return AccessionMetric(
                code: code,
                title: title,
                notes: notes,
                capacity: capacity,
                bed: bed,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a accession metric in status planned.
    static func newAccessionMetric(_ code: String, title: String) -> AccessionMetric {
        return AccessionMetric(
            code: code,
            title: title,
            notes: "",
            capacity: 0,
            bed: "",
            rate: 0.0,
            status: AccessionMetricStatus.planned
        )
    }
}
