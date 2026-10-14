import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen target is in its life cycle.
    enum SpecimenTargetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A specimen target. Its code is unique within a tenant.
    final class SpecimenTarget {
        var code: String
        var label: String
        var currency: String
        var phone: String
        var budget: Double
        var status: SpecimenTargetStatus

        init(code: String, label: String, currency: String, phone: String, budget: Double, status: SpecimenTargetStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.phone = phone
            self.budget = budget
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

        func canMoveTo(_ next: SpecimenTargetStatus) -> Bool {
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
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == SpecimenTargetStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("specimen target") \(code)"
        }

        func measuredValue() -> Double {
            return budget
        }

        func copyValue() -> SpecimenTarget {
            return SpecimenTarget(
                code: code,
                label: label,
                currency: currency,
                phone: phone,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a specimen target in status draft.
    static func newSpecimenTarget(_ code: String, label: String) -> SpecimenTarget {
        return SpecimenTarget(
            code: code,
            label: label,
            currency: "",
            phone: "",
            budget: 0.0,
            status: SpecimenTargetStatus.draft
        )
    }
}
