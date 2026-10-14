import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a manual rounding budget is in its life cycle.
    enum ManualRoundingBudgetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One manual rounding budget, with what the planners need to act on it.
    final class ManualRoundingBudget {
        var code: String
        var title: String
        var floorValue: Double
        var archived: Bool
        var visitMinutes: Int
        var attributes: [String: String]
        var status: ManualRoundingBudgetStatus

        init(code: String, title: String, floorValue: Double, archived: Bool, visitMinutes: Int, attributes: [String: String], status: ManualRoundingBudgetStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.archived = archived
            self.visitMinutes = visitMinutes
            self.attributes = attributes
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

        func canMoveTo(_ next: ManualRoundingBudgetStatus) -> Bool {
            switch status {
            case .idle:
                return next == ManualRoundingBudgetStatus.ready || next == ManualRoundingBudgetStatus.draining
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == ManualRoundingBudgetStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualRoundingBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual rounding budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedValue() -> Double {
            return ((Double(visitMinutes) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> ManualRoundingBudget {
            return ManualRoundingBudget(
                code: code,
                title: title,
                floorValue: floorValue,
                archived: archived,
                visitMinutes: visitMinutes,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual rounding budget in status idle.
    static func newManualRoundingBudget(_ code: String, title: String) -> ManualRoundingBudget {
        return ManualRoundingBudget(
            code: code,
            title: title,
            floorValue: 0.0,
            archived: false,
            visitMinutes: 0,
            attributes: [:],
            status: ManualRoundingBudgetStatus.idle
        )
    }
}
