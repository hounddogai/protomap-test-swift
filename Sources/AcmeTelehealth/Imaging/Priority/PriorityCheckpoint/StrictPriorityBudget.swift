import AcmePlatform
import Foundation

extension Imaging {
    /// Where a strict priority budget is in its life cycle.
    enum StrictPriorityBudgetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A strict priority budget as the priority team keeps it.
    final class StrictPriorityBudget {
        var code: String
        var name: String
        var startsAt: Int
        var description: String
        var batchSize: Int
        var patientRef: String
        var rate: Double
        var graceDays: Int
        var status: StrictPriorityBudgetStatus

        init(code: String, name: String, startsAt: Int, description: String, batchSize: Int, patientRef: String, rate: Double, graceDays: Int, status: StrictPriorityBudgetStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.description = description
            self.batchSize = batchSize
            self.patientRef = patientRef
            self.rate = rate
            self.graceDays = graceDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictPriorityBudgetStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == StrictPriorityBudgetStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: StrictPriorityBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict priority budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedExposure() -> Double {
            return ((rate + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> StrictPriorityBudget {
            return StrictPriorityBudget(
                code: code,
                name: name,
                startsAt: startsAt,
                description: description,
                batchSize: batchSize,
                patientRef: patientRef,
                rate: rate,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict priority budget in status proposed.
    static func newStrictPriorityBudget(_ code: String, name: String) -> StrictPriorityBudget {
        return StrictPriorityBudget(
            code: code,
            name: name,
            startsAt: 0,
            description: "",
            batchSize: 0,
            patientRef: "",
            rate: 0.0,
            graceDays: 0,
            status: StrictPriorityBudgetStatus.proposed
        )
    }
}
