import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction template is in its life cycle.
    enum InteractionTemplateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A interaction template as the interaction team keeps it.
    final class InteractionTemplate {
        var code: String
        var label: String
        var capacity: Int
        var copay: Double
        var dosageMg: Double
        var limit: Int
        var weight: Double
        var contactEmail: String
        var createdAt: Int
        var visible: Bool
        var status: InteractionTemplateStatus

        init(code: String, label: String, capacity: Int, copay: Double, dosageMg: Double, limit: Int, weight: Double, contactEmail: String, createdAt: Int, visible: Bool, status: InteractionTemplateStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.copay = copay
            self.dosageMg = dosageMg
            self.limit = limit
            self.weight = weight
            self.contactEmail = contactEmail
            self.createdAt = createdAt
            self.visible = visible
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

        func canMoveTo(_ next: InteractionTemplateStatus) -> Bool {
            switch status {
            case .draft:
                return next == InteractionTemplateStatus.pending || next == InteractionTemplateStatus.closed
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == InteractionTemplateStatus.suspended || next == InteractionTemplateStatus.closed
            case .suspended:
                return next == InteractionTemplateStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InteractionTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("interaction template") \(code)"
        }

        func weightedTotal() -> Double {
            return (Double(createdAt) * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> InteractionTemplate {
            return InteractionTemplate(
                code: code,
                label: label,
                capacity: capacity,
                copay: copay,
                dosageMg: dosageMg,
                limit: limit,
                weight: weight,
                contactEmail: contactEmail,
                createdAt: createdAt,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a interaction template in status draft.
    static func newInteractionTemplate(_ code: String, label: String) -> InteractionTemplate {
        return InteractionTemplate(
            code: code,
            label: label,
            capacity: 0,
            copay: 0.0,
            dosageMg: 0.0,
            limit: 0,
            weight: 0.0,
            contactEmail: "",
            createdAt: 0,
            visible: false,
            status: InteractionTemplateStatus.draft
        )
    }
}
