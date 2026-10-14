import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a capped remittance template is in its life cycle.
    enum CappedRemittanceTemplateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A capped remittance template. Its code is unique within a tenant.
    final class CappedRemittanceTemplate {
        var code: String
        var name: String
        var region: String
        var quantity: Int
        var budget: Double
        var archived: Bool
        var active: Bool
        var procedureCode: String
        var visible: Bool
        var status: CappedRemittanceTemplateStatus

        init(code: String, name: String, region: String, quantity: Int, budget: Double, archived: Bool, active: Bool, procedureCode: String, visible: Bool, status: CappedRemittanceTemplateStatus) {
            self.code = code
            self.name = name
            self.region = region
            self.quantity = quantity
            self.budget = budget
            self.archived = archived
            self.active = active
            self.procedureCode = procedureCode
            self.visible = visible
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

        func canMoveTo(_ next: CappedRemittanceTemplateStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == CappedRemittanceTemplateStatus.archived
            case .reopened:
                return next == CappedRemittanceTemplateStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedRemittanceTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped remittance template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedExposure() -> Double {
            return ((Double(quantity) + budget) * 100).rounded() / 100
        }

        func copyValue() -> CappedRemittanceTemplate {
            return CappedRemittanceTemplate(
                code: code,
                name: name,
                region: region,
                quantity: quantity,
                budget: budget,
                archived: archived,
                active: active,
                procedureCode: procedureCode,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a capped remittance template in status open.
    static func newCappedRemittanceTemplate(_ code: String, name: String) -> CappedRemittanceTemplate {
        return CappedRemittanceTemplate(
            code: code,
            name: name,
            region: "",
            quantity: 0,
            budget: 0.0,
            archived: false,
            active: false,
            procedureCode: "",
            visible: false,
            status: CappedRemittanceTemplateStatus.`open`
        )
    }
}
