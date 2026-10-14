import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary allocation is in its life cycle.
    enum FormularyAllocationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A formulary allocation. Its code is unique within a tenant.
    final class FormularyAllocation {
        var code: String
        var label: String
        var quantity: Int
        var amount: Double
        var ceiling: Double
        var expiresAt: Int
        var attributes: [String: String]
        var approved: Bool
        var status: FormularyAllocationStatus

        init(code: String, label: String, quantity: Int, amount: Double, ceiling: Double, expiresAt: Int, attributes: [String: String], approved: Bool, status: FormularyAllocationStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.amount = amount
            self.ceiling = ceiling
            self.expiresAt = expiresAt
            self.attributes = attributes
            self.approved = approved
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FormularyAllocationStatus) -> Bool {
            switch status {
            case .`open`:
                return next == FormularyAllocationStatus.reopened || next == FormularyAllocationStatus.archived
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == FormularyAllocationStatus.reopened || next == FormularyAllocationStatus.archived
            case .reopened:
                return next == FormularyAllocationStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FormularyAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
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

        func netExposure() -> Double {
            return ((amount - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> FormularyAllocation {
            return FormularyAllocation(
                code: code,
                label: label,
                quantity: quantity,
                amount: amount,
                ceiling: ceiling,
                expiresAt: expiresAt,
                attributes: attributes,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a formulary allocation in status open.
    static func newFormularyAllocation(_ code: String, label: String) -> FormularyAllocation {
        return FormularyAllocation(
            code: code,
            label: label,
            quantity: 0,
            amount: 0.0,
            ceiling: 0.0,
            expiresAt: 0,
            attributes: [:],
            approved: false,
            status: FormularyAllocationStatus.`open`
        )
    }
}
