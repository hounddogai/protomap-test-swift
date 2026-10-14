import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel budget is in its life cycle.
    enum PanelBudgetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A panel budget as the panel team keeps it.
    final class PanelBudget {
        var code: String
        var title: String
        var expiresAt: Int
        var name: String
        var visible: Bool
        var allergy: String
        var ownerID: String
        var label: String
        var budget: Double
        var status: PanelBudgetStatus

        init(code: String, title: String, expiresAt: Int, name: String, visible: Bool, allergy: String, ownerID: String, label: String, budget: Double, status: PanelBudgetStatus) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.name = name
            self.visible = visible
            self.allergy = allergy
            self.ownerID = ownerID
            self.label = label
            self.budget = budget
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

        func canMoveTo(_ next: PanelBudgetStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == PanelBudgetStatus.rejected || next == PanelBudgetStatus.withdrawn
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

        func moveTo(_ next: PanelBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("panel budget") \(code)"
        }

        func netExposure() -> Double {
            return ((Double(expiresAt) + budget) * 100).rounded() / 100
        }

        func copyValue() -> PanelBudget {
            return PanelBudget(
                code: code,
                title: title,
                expiresAt: expiresAt,
                name: name,
                visible: visible,
                allergy: allergy,
                ownerID: ownerID,
                label: label,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a panel budget in status proposed.
    static func newPanelBudget(_ code: String, title: String) -> PanelBudget {
        return PanelBudget(
            code: code,
            title: title,
            expiresAt: 0,
            name: "",
            visible: false,
            allergy: "",
            ownerID: "",
            label: "",
            budget: 0.0,
            status: PanelBudgetStatus.proposed
        )
    }
}
