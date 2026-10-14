import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a strict bed board draft is in its life cycle.
    enum StrictBedBoardDraftStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A strict bed board draft as the bed board team keeps it.
    final class StrictBedBoardDraft {
        var code: String
        var label: String
        var country: String
        var currency: String
        var category: String
        var contactEmail: String
        var amount: Double
        var status: StrictBedBoardDraftStatus

        init(code: String, label: String, country: String, currency: String, category: String, contactEmail: String, amount: Double, status: StrictBedBoardDraftStatus) {
            self.code = code
            self.label = label
            self.country = country
            self.currency = currency
            self.category = category
            self.contactEmail = contactEmail
            self.amount = amount
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

        func canMoveTo(_ next: StrictBedBoardDraftStatus) -> Bool {
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
                return next == StrictBedBoardDraftStatus.active || next == StrictBedBoardDraftStatus.suspended
            case .active:
                return next == StrictBedBoardDraftStatus.suspended
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

        func moveTo(_ next: StrictBedBoardDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict bed board draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> StrictBedBoardDraft {
            return StrictBedBoardDraft(
                code: code,
                label: label,
                country: country,
                currency: currency,
                category: category,
                contactEmail: contactEmail,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a strict bed board draft in status draft.
    static func newStrictBedBoardDraft(_ code: String, label: String) -> StrictBedBoardDraft {
        return StrictBedBoardDraft(
            code: code,
            label: label,
            country: "",
            currency: "",
            category: "",
            contactEmail: "",
            amount: 0.0,
            status: StrictBedBoardDraftStatus.draft
        )
    }
}
