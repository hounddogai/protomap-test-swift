import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a scheduled authorization metric is in its life cycle.
    enum ScheduledAuthorizationMetricStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One scheduled authorization metric, with what the planners need to act on it.
    final class ScheduledAuthorizationMetric {
        var code: String
        var label: String
        var revision: Int
        var bed: String
        var capacity: Int
        var weight: Double
        var title: String
        var visitMinutes: Int
        var status: ScheduledAuthorizationMetricStatus

        init(code: String, label: String, revision: Int, bed: String, capacity: Int, weight: Double, title: String, visitMinutes: Int, status: ScheduledAuthorizationMetricStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.bed = bed
            self.capacity = capacity
            self.weight = weight
            self.title = title
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: ScheduledAuthorizationMetricStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ScheduledAuthorizationMetricStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == ScheduledAuthorizationMetricStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledAuthorizationMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled authorization metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedValue() -> Double {
            return (weight * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledAuthorizationMetric {
            return ScheduledAuthorizationMetric(
                code: code,
                label: label,
                revision: revision,
                bed: bed,
                capacity: capacity,
                weight: weight,
                title: title,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled authorization metric in status draft.
    static func newScheduledAuthorizationMetric(_ code: String, label: String) -> ScheduledAuthorizationMetric {
        return ScheduledAuthorizationMetric(
            code: code,
            label: label,
            revision: 0,
            bed: "",
            capacity: 0,
            weight: 0.0,
            title: "",
            visitMinutes: 0,
            status: ScheduledAuthorizationMetricStatus.draft
        )
    }
}
