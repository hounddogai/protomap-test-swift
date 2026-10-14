import AcmePlatform
import Foundation

extension Consent {
    /// Where a weighted proxy summary is in its life cycle.
    enum WeightedProxySummaryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One weighted proxy summary, with what the planners need to act on it.
    final class WeightedProxySummary {
        var code: String
        var name: String
        var discount: Double
        var archived: Bool
        var facility: String
        var quantity: Int
        var phone: String
        var locale: String
        var label: String
        var dosageMg: Double
        var status: WeightedProxySummaryStatus

        init(code: String, name: String, discount: Double, archived: Bool, facility: String, quantity: Int, phone: String, locale: String, label: String, dosageMg: Double, status: WeightedProxySummaryStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.archived = archived
            self.facility = facility
            self.quantity = quantity
            self.phone = phone
            self.locale = locale
            self.label = label
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

        func canMoveTo(_ next: WeightedProxySummaryStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == WeightedProxySummaryStatus.suspended || next == WeightedProxySummaryStatus.closed
            case .suspended:
                return next == WeightedProxySummaryStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedProxySummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted proxy summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func projectedLoad() -> Double {
            return (Double(quantity) * discount * 100).rounded() / 100
        }

        func copyValue() -> WeightedProxySummary {
            return WeightedProxySummary(
                code: code,
                name: name,
                discount: discount,
                archived: archived,
                facility: facility,
                quantity: quantity,
                phone: phone,
                locale: locale,
                label: label,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a weighted proxy summary in status draft.
    static func newWeightedProxySummary(_ code: String, name: String) -> WeightedProxySummary {
        return WeightedProxySummary(
            code: code,
            name: name,
            discount: 0.0,
            archived: false,
            facility: "",
            quantity: 0,
            phone: "",
            locale: "",
            label: "",
            dosageMg: 0.0,
            status: WeightedProxySummaryStatus.draft
        )
    }
}
