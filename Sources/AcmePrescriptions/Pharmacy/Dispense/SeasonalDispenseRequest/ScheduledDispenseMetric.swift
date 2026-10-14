import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a scheduled dispense metric is in its life cycle.
    enum ScheduledDispenseMetricStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a scheduled dispense metric and its current status.
    final class ScheduledDispenseMetric {
        var code: String
        var name: String
        var maximum: Double
        var visible: Bool
        var durationMinutes: Int
        var rate: Double
        var contactEmail: String
        var updatedAt: Int
        var status: ScheduledDispenseMetricStatus

        init(code: String, name: String, maximum: Double, visible: Bool, durationMinutes: Int, rate: Double, contactEmail: String, updatedAt: Int, status: ScheduledDispenseMetricStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.visible = visible
            self.durationMinutes = durationMinutes
            self.rate = rate
            self.contactEmail = contactEmail
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: ScheduledDispenseMetricStatus) -> Bool {
            switch status {
            case .created:
                return next == ScheduledDispenseMetricStatus.published || next == ScheduledDispenseMetricStatus.retired
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == ScheduledDispenseMetricStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledDispenseMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled dispense metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedTotal() -> Double {
            return ((rate - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledDispenseMetric {
            return ScheduledDispenseMetric(
                code: code,
                name: name,
                maximum: maximum,
                visible: visible,
                durationMinutes: durationMinutes,
                rate: rate,
                contactEmail: contactEmail,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled dispense metric in status created.
    static func newScheduledDispenseMetric(_ code: String, name: String) -> ScheduledDispenseMetric {
        return ScheduledDispenseMetric(
            code: code,
            name: name,
            maximum: 0.0,
            visible: false,
            durationMinutes: 0,
            rate: 0.0,
            contactEmail: "",
            updatedAt: 0,
            status: ScheduledDispenseMetricStatus.created
        )
    }
}
