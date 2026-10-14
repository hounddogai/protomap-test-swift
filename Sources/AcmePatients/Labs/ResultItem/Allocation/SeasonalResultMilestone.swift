import AcmePlatform
import Foundation

extension Labs {
    /// Where a seasonal result milestone is in its life cycle.
    enum SeasonalResultMilestoneStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A seasonal result milestone. Its code is unique within a tenant.
    final class SeasonalResultMilestone {
        var code: String
        var name: String
        var facility: String
        var unit: String
        var score: Double
        var capacity: Int
        var sequence: Int
        var status: SeasonalResultMilestoneStatus

        init(code: String, name: String, facility: String, unit: String, score: Double, capacity: Int, sequence: Int, status: SeasonalResultMilestoneStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.unit = unit
            self.score = score
            self.capacity = capacity
            self.sequence = sequence
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

        func canMoveTo(_ next: SeasonalResultMilestoneStatus) -> Bool {
            switch status {
            case .draft:
                return next == SeasonalResultMilestoneStatus.active || next == SeasonalResultMilestoneStatus.suspended
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == SeasonalResultMilestoneStatus.suspended || next == SeasonalResultMilestoneStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: SeasonalResultMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal result milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedExposure() -> Double {
            return ((Double(capacity) - score) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalResultMilestone {
            return SeasonalResultMilestone(
                code: code,
                name: name,
                facility: facility,
                unit: unit,
                score: score,
                capacity: capacity,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a seasonal result milestone in status draft.
    static func newSeasonalResultMilestone(_ code: String, name: String) -> SeasonalResultMilestone {
        return SeasonalResultMilestone(
            code: code,
            name: name,
            facility: "",
            unit: "",
            score: 0.0,
            capacity: 0,
            sequence: 0,
            status: SeasonalResultMilestoneStatus.draft
        )
    }
}
