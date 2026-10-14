import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a global interaction budget is in its life cycle.
    enum GlobalInteractionBudgetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A global interaction budget. Its code is unique within a tenant.
    final class GlobalInteractionBudget {
        var code: String
        var name: String
        var tags: [String]
        var ratio: Double
        var minimum: Double
        var unit: String
        var archived: Bool
        var procedureCode: String
        var score: Double
        var channel: String
        var ownerID: String
        var status: GlobalInteractionBudgetStatus

        init(code: String, name: String, tags: [String], ratio: Double, minimum: Double, unit: String, archived: Bool, procedureCode: String, score: Double, channel: String, ownerID: String, status: GlobalInteractionBudgetStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.ratio = ratio
            self.minimum = minimum
            self.unit = unit
            self.archived = archived
            self.procedureCode = procedureCode
            self.score = score
            self.channel = channel
            self.ownerID = ownerID
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

        func canMoveTo(_ next: GlobalInteractionBudgetStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == GlobalInteractionBudgetStatus.completed
            case .inProgress:
                return next == GlobalInteractionBudgetStatus.completed || next == GlobalInteractionBudgetStatus.cancelled
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

        func moveTo(_ next: GlobalInteractionBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global interaction budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedLoad() -> Double {
            return ((minimum - score) * 100).rounded() / 100
        }

        func copyValue() -> GlobalInteractionBudget {
            return GlobalInteractionBudget(
                code: code,
                name: name,
                tags: tags,
                ratio: ratio,
                minimum: minimum,
                unit: unit,
                archived: archived,
                procedureCode: procedureCode,
                score: score,
                channel: channel,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a global interaction budget in status planned.
    static func newGlobalInteractionBudget(_ code: String, name: String) -> GlobalInteractionBudget {
        return GlobalInteractionBudget(
            code: code,
            name: name,
            tags: [],
            ratio: 0.0,
            minimum: 0.0,
            unit: "",
            archived: false,
            procedureCode: "",
            score: 0.0,
            channel: "",
            ownerID: "",
            status: GlobalInteractionBudgetStatus.planned
        )
    }
}
