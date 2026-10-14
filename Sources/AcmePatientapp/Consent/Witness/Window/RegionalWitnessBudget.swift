import AcmePlatform
import Foundation

extension Consent {
    /// Where a regional witness budget is in its life cycle.
    enum RegionalWitnessBudgetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A regional witness budget. Its code is unique within a tenant.
    final class RegionalWitnessBudget {
        var code: String
        var title: String
        var amount: Double
        var facility: String
        var phone: String
        var status: RegionalWitnessBudgetStatus

        init(code: String, title: String, amount: Double, facility: String, phone: String, status: RegionalWitnessBudgetStatus) {
            self.code = code
            self.title = title
            self.amount = amount
            self.facility = facility
            self.phone = phone
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

        func canMoveTo(_ next: RegionalWitnessBudgetStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == RegionalWitnessBudgetStatus.resolved
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: RegionalWitnessBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional witness budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> RegionalWitnessBudget {
            return RegionalWitnessBudget(
                code: code,
                title: title,
                amount: amount,
                facility: facility,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a regional witness budget in status open.
    static func newRegionalWitnessBudget(_ code: String, title: String) -> RegionalWitnessBudget {
        return RegionalWitnessBudget(
            code: code,
            title: title,
            amount: 0.0,
            facility: "",
            phone: "",
            status: RegionalWitnessBudgetStatus.`open`
        )
    }
}
