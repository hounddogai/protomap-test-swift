import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority template is in its life cycle.
    enum PriorityTemplateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A priority template as the priority team keeps it.
    final class PriorityTemplate {
        var code: String
        var label: String
        var quantity: Int
        var expiresAt: Int
        var phone: String
        var source: String
        var description: String
        var status: PriorityTemplateStatus

        init(code: String, label: String, quantity: Int, expiresAt: Int, phone: String, source: String, description: String, status: PriorityTemplateStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.expiresAt = expiresAt
            self.phone = phone
            self.source = source
            self.description = description
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

        func canMoveTo(_ next: PriorityTemplateStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PriorityTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedTotal() -> Double {
            return ((Double(quantity) + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> PriorityTemplate {
            return PriorityTemplate(
                code: code,
                label: label,
                quantity: quantity,
                expiresAt: expiresAt,
                phone: phone,
                source: source,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a priority template in status draft.
    static func newPriorityTemplate(_ code: String, label: String) -> PriorityTemplate {
        return PriorityTemplate(
            code: code,
            label: label,
            quantity: 0,
            expiresAt: 0,
            phone: "",
            source: "",
            description: "",
            status: PriorityTemplateStatus.draft
        )
    }
}
