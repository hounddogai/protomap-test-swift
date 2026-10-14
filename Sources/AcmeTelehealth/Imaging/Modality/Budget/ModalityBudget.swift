import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality budget is in its life cycle.
    enum ModalityBudgetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a modality budget and its current status.
    final class ModalityBudget {
        var code: String
        var label: String
        var unit: String
        var createdAt: Int
        var capacity: Int
        var visible: Bool
        var quantity: Int
        var procedureCode: String
        var status: ModalityBudgetStatus

        init(code: String, label: String, unit: String, createdAt: Int, capacity: Int, visible: Bool, quantity: Int, procedureCode: String, status: ModalityBudgetStatus) {
            self.code = code
            self.label = label
            self.unit = unit
            self.createdAt = createdAt
            self.capacity = capacity
            self.visible = visible
            self.quantity = quantity
            self.procedureCode = procedureCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ModalityBudgetStatus) -> Bool {
            switch status {
            case .requested:
                return next == ModalityBudgetStatus.revoked || next == ModalityBudgetStatus.expired
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ModalityBudgetStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ModalityBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("modality budget") \(code)"
        }

        func netTotal() -> Double {
            return (Double(capacity) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> ModalityBudget {
            return ModalityBudget(
                code: code,
                label: label,
                unit: unit,
                createdAt: createdAt,
                capacity: capacity,
                visible: visible,
                quantity: quantity,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a modality budget in status requested.
    static func newModalityBudget(_ code: String, label: String) -> ModalityBudget {
        return ModalityBudget(
            code: code,
            label: label,
            unit: "",
            createdAt: 0,
            capacity: 0,
            visible: false,
            quantity: 0,
            procedureCode: "",
            status: ModalityBudgetStatus.requested
        )
    }
}
