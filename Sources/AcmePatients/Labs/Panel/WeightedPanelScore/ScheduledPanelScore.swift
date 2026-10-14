import AcmePlatform
import Foundation

extension Labs {
    /// Where a scheduled panel score is in its life cycle.
    enum ScheduledPanelScoreStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A scheduled panel score. Its code is unique within a tenant.
    final class ScheduledPanelScore {
        var code: String
        var name: String
        var maximum: Double
        var capacity: Int
        var externalRef: String
        var visitMinutes: Int
        var ward: String
        var currency: String
        var region: String
        var cost: Double
        var status: ScheduledPanelScoreStatus

        init(code: String, name: String, maximum: Double, capacity: Int, externalRef: String, visitMinutes: Int, ward: String, currency: String, region: String, cost: Double, status: ScheduledPanelScoreStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.capacity = capacity
            self.externalRef = externalRef
            self.visitMinutes = visitMinutes
            self.ward = ward
            self.currency = currency
            self.region = region
            self.cost = cost
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

        func canMoveTo(_ next: ScheduledPanelScoreStatus) -> Bool {
            switch status {
            case .idle:
                return next == ScheduledPanelScoreStatus.stopped
            case .warming:
                return next == ScheduledPanelScoreStatus.stopped
            case .ready:
                return next == ScheduledPanelScoreStatus.stopped
            case .draining:
                return next == ScheduledPanelScoreStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledPanelScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled panel score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netLoad() -> Double {
            return ((Double(capacity) + cost) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledPanelScore {
            return ScheduledPanelScore(
                code: code,
                name: name,
                maximum: maximum,
                capacity: capacity,
                externalRef: externalRef,
                visitMinutes: visitMinutes,
                ward: ward,
                currency: currency,
                region: region,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a scheduled panel score in status idle.
    static func newScheduledPanelScore(_ code: String, name: String) -> ScheduledPanelScore {
        return ScheduledPanelScore(
            code: code,
            name: name,
            maximum: 0.0,
            capacity: 0,
            externalRef: "",
            visitMinutes: 0,
            ward: "",
            currency: "",
            region: "",
            cost: 0.0,
            status: ScheduledPanelScoreStatus.idle
        )
    }
}
