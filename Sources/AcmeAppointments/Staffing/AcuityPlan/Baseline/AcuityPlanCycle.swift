import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan cycle is in its life cycle.
    enum AcuityPlanCycleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One acuity plan cycle, with what the planners need to act on it.
    final class AcuityPlanCycle {
        var code: String
        var name: String
        var capacity: Int
        var expiresAt: Int
        var unit: String
        var locale: String
        var score: Double
        var phone: String
        var status: AcuityPlanCycleStatus

        init(code: String, name: String, capacity: Int, expiresAt: Int, unit: String, locale: String, score: Double, phone: String, status: AcuityPlanCycleStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.expiresAt = expiresAt
            self.unit = unit
            self.locale = locale
            self.score = score
            self.phone = phone
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

        func canMoveTo(_ next: AcuityPlanCycleStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == AcuityPlanCycleStatus.inProgress || next == AcuityPlanCycleStatus.cancelled
            case .inProgress:
                return next == AcuityPlanCycleStatus.completed || next == AcuityPlanCycleStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: AcuityPlanCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedVolume() -> Double {
            return ((Double(expiresAt) - score) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanCycle {
            return AcuityPlanCycle(
                code: code,
                name: name,
                capacity: capacity,
                expiresAt: expiresAt,
                unit: unit,
                locale: locale,
                score: score,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a acuity plan cycle in status planned.
    static func newAcuityPlanCycle(_ code: String, name: String) -> AcuityPlanCycle {
        return AcuityPlanCycle(
            code: code,
            name: name,
            capacity: 0,
            expiresAt: 0,
            unit: "",
            locale: "",
            score: 0.0,
            phone: "",
            status: AcuityPlanCycleStatus.planned
        )
    }
}
