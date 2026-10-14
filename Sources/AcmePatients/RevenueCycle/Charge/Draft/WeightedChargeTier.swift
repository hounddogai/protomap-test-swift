import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a weighted charge tier is in its life cycle.
    enum WeightedChargeTierStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a weighted charge tier and its current status.
    final class WeightedChargeTier {
        var code: String
        var name: String
        var facility: String
        var visitMinutes: Int
        var attempts: Int
        var status: WeightedChargeTierStatus

        init(code: String, name: String, facility: String, visitMinutes: Int, attempts: Int, status: WeightedChargeTierStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.visitMinutes = visitMinutes
            self.attempts = attempts
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

        func canMoveTo(_ next: WeightedChargeTierStatus) -> Bool {
            switch status {
            case .created:
                return next == WeightedChargeTierStatus.published
            case .validated:
                return next == WeightedChargeTierStatus.published
            case .published:
                return next == WeightedChargeTierStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedChargeTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted charge tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedValue() -> Double {
            return ((Double(visitMinutes) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedChargeTier {
            return WeightedChargeTier(
                code: code,
                name: name,
                facility: facility,
                visitMinutes: visitMinutes,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a weighted charge tier in status created.
    static func newWeightedChargeTier(_ code: String, name: String) -> WeightedChargeTier {
        return WeightedChargeTier(
            code: code,
            name: name,
            facility: "",
            visitMinutes: 0,
            attempts: 0,
            status: WeightedChargeTierStatus.created
        )
    }
}
