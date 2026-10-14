import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall metric is in its life cycle.
    enum RecallMetricStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A recall metric. Its code is unique within a tenant.
    final class RecallMetric {
        var code: String
        var name: String
        var visible: Bool
        var source: String
        var limit: Int
        var specialty: String
        var title: String
        var status: RecallMetricStatus

        init(code: String, name: String, visible: Bool, source: String, limit: Int, specialty: String, title: String, status: RecallMetricStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.source = source
            self.limit = limit
            self.specialty = specialty
            self.title = title
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

        func canMoveTo(_ next: RecallMetricStatus) -> Bool {
            switch status {
            case .idle:
                return next == RecallMetricStatus.draining || next == RecallMetricStatus.stopped
            case .warming:
                return next == RecallMetricStatus.draining || next == RecallMetricStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: RecallMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("recall metric") \(code)"
        }

        func measuredValue() -> Double {
            return Double(limit)
        }

        func copyValue() -> RecallMetric {
            return RecallMetric(
                code: code,
                name: name,
                visible: visible,
                source: source,
                limit: limit,
                specialty: specialty,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a recall metric in status idle.
    static func newRecallMetric(_ code: String, name: String) -> RecallMetric {
        return RecallMetric(
            code: code,
            name: name,
            visible: false,
            source: "",
            limit: 0,
            specialty: "",
            title: "",
            status: RecallMetricStatus.idle
        )
    }
}
