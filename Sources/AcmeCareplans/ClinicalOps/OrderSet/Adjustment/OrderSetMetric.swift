import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set metric is in its life cycle.
    enum OrderSetMetricStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A order set metric as the order set team keeps it.
    final class OrderSetMetric {
        var code: String
        var title: String
        var windowDays: Int
        var budget: Double
        var priority: Int
        var pinned: Bool
        var tags: [String]
        var name: String
        var source: String
        var status: OrderSetMetricStatus

        init(code: String, title: String, windowDays: Int, budget: Double, priority: Int, pinned: Bool, tags: [String], name: String, source: String, status: OrderSetMetricStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.budget = budget
            self.priority = priority
            self.pinned = pinned
            self.tags = tags
            self.name = name
            self.source = source
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

        func canMoveTo(_ next: OrderSetMetricStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == OrderSetMetricStatus.published || next == OrderSetMetricStatus.retired
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

        func moveTo(_ next: OrderSetMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedTotal() -> Double {
            return (Double(priority) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetMetric {
            return OrderSetMetric(
                code: code,
                title: title,
                windowDays: windowDays,
                budget: budget,
                priority: priority,
                pinned: pinned,
                tags: tags,
                name: name,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a order set metric in status created.
    static func newOrderSetMetric(_ code: String, title: String) -> OrderSetMetric {
        return OrderSetMetric(
            code: code,
            title: title,
            windowDays: 0,
            budget: 0.0,
            priority: 0,
            pinned: false,
            tags: [],
            name: "",
            source: "",
            status: OrderSetMetricStatus.created
        )
    }
}
