import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a seasonal interaction checkpoint is in its life cycle.
    enum SeasonalInteractionCheckpointStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a seasonal interaction checkpoint and its current status.
    final class SeasonalInteractionCheckpoint {
        var code: String
        var name: String
        var category: String
        var amount: Double
        var label: String
        var reviewer: String
        var visible: Bool
        var copay: Double
        var description: String
        var dosageMg: Double
        var status: SeasonalInteractionCheckpointStatus

        init(code: String, name: String, category: String, amount: Double, label: String, reviewer: String, visible: Bool, copay: Double, description: String, dosageMg: Double, status: SeasonalInteractionCheckpointStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.amount = amount
            self.label = label
            self.reviewer = reviewer
            self.visible = visible
            self.copay = copay
            self.description = description
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: SeasonalInteractionCheckpointStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == SeasonalInteractionCheckpointStatus.active || next == SeasonalInteractionCheckpointStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == SeasonalInteractionCheckpointStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalInteractionCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal interaction checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("seasonal interaction checkpoint") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((copay + amount) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalInteractionCheckpoint {
            return SeasonalInteractionCheckpoint(
                code: code,
                name: name,
                category: category,
                amount: amount,
                label: label,
                reviewer: reviewer,
                visible: visible,
                copay: copay,
                description: description,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a seasonal interaction checkpoint in status draft.
    static func newSeasonalInteractionCheckpoint(_ code: String, name: String) -> SeasonalInteractionCheckpoint {
        return SeasonalInteractionCheckpoint(
            code: code,
            name: name,
            category: "",
            amount: 0.0,
            label: "",
            reviewer: "",
            visible: false,
            copay: 0.0,
            description: "",
            dosageMg: 0.0,
            status: SeasonalInteractionCheckpointStatus.draft
        )
    }
}
