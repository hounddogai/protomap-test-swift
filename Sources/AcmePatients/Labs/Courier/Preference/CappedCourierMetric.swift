import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped courier metric is in its life cycle.
    enum CappedCourierMetricStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One capped courier metric, with what the planners need to act on it.
    final class CappedCourierMetric {
        var code: String
        var name: String
        var visible: Bool
        var budget: Double
        var visitMinutes: Int
        var cost: Double
        var phone: String
        var retries: Int
        var status: CappedCourierMetricStatus

        init(code: String, name: String, visible: Bool, budget: Double, visitMinutes: Int, cost: Double, phone: String, retries: Int, status: CappedCourierMetricStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.budget = budget
            self.visitMinutes = visitMinutes
            self.cost = cost
            self.phone = phone
            self.retries = retries
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

        func canMoveTo(_ next: CappedCourierMetricStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == CappedCourierMetricStatus.draining
            case .ready:
                switch next {
                case .stopped:
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

        func moveTo(_ next: CappedCourierMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped courier metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("capped courier metric") \(code)"
        }

        func weightedTotal() -> Double {
            return ((cost + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> CappedCourierMetric {
            return CappedCourierMetric(
                code: code,
                name: name,
                visible: visible,
                budget: budget,
                visitMinutes: visitMinutes,
                cost: cost,
                phone: phone,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped courier metric in status idle.
    static func newCappedCourierMetric(_ code: String, name: String) -> CappedCourierMetric {
        return CappedCourierMetric(
            code: code,
            name: name,
            visible: false,
            budget: 0.0,
            visitMinutes: 0,
            cost: 0.0,
            phone: "",
            retries: 0,
            status: CappedCourierMetricStatus.idle
        )
    }
}
