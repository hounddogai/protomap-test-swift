import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure template is in its life cycle.
    enum DisclosureTemplateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One disclosure template, with what the planners need to act on it.
    final class DisclosureTemplate {
        var code: String
        var title: String
        var source: String
        var active: Bool
        var unit: String
        var quantity: Int
        var allergy: String
        var status: DisclosureTemplateStatus

        init(code: String, title: String, source: String, active: Bool, unit: String, quantity: Int, allergy: String, status: DisclosureTemplateStatus) {
            self.code = code
            self.title = title
            self.source = source
            self.active = active
            self.unit = unit
            self.quantity = quantity
            self.allergy = allergy
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

        func canMoveTo(_ next: DisclosureTemplateStatus) -> Bool {
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
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == DisclosureTemplateStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DisclosureTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("disclosure template") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> DisclosureTemplate {
            return DisclosureTemplate(
                code: code,
                title: title,
                source: source,
                active: active,
                unit: unit,
                quantity: quantity,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a disclosure template in status proposed.
    static func newDisclosureTemplate(_ code: String, title: String) -> DisclosureTemplate {
        return DisclosureTemplate(
            code: code,
            title: title,
            source: "",
            active: false,
            unit: "",
            quantity: 0,
            allergy: "",
            status: DisclosureTemplateStatus.proposed
        )
    }
}
