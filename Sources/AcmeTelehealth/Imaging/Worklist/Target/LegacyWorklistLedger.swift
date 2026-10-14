import AcmePlatform
import Foundation

extension Imaging {
    /// Where a legacy worklist ledger is in its life cycle.
    enum LegacyWorklistLedgerStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A legacy worklist ledger as the worklist team keeps it.
    final class LegacyWorklistLedger {
        var code: String
        var label: String
        var category: String
        var channel: String
        var phone: String
        var facility: String
        var title: String
        var notes: String
        var amount: Double
        var rate: Double
        var status: LegacyWorklistLedgerStatus

        init(code: String, label: String, category: String, channel: String, phone: String, facility: String, title: String, notes: String, amount: Double, rate: Double, status: LegacyWorklistLedgerStatus) {
            self.code = code
            self.label = label
            self.category = category
            self.channel = channel
            self.phone = phone
            self.facility = facility
            self.title = title
            self.notes = notes
            self.amount = amount
            self.rate = rate
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

        func canMoveTo(_ next: LegacyWorklistLedgerStatus) -> Bool {
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
                return next == LegacyWorklistLedgerStatus.active || next == LegacyWorklistLedgerStatus.suspended
            case .active:
                switch next {
                case .suspended:
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

        func moveTo(_ next: LegacyWorklistLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy worklist ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("legacy worklist ledger") \(code)"
        }

        func weightedLoad() -> Double {
            return (rate * amount * 100).rounded() / 100
        }

        func copyValue() -> LegacyWorklistLedger {
            return LegacyWorklistLedger(
                code: code,
                label: label,
                category: category,
                channel: channel,
                phone: phone,
                facility: facility,
                title: title,
                notes: notes,
                amount: amount,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a legacy worklist ledger in status draft.
    static func newLegacyWorklistLedger(_ code: String, label: String) -> LegacyWorklistLedger {
        return LegacyWorklistLedger(
            code: code,
            label: label,
            category: "",
            channel: "",
            phone: "",
            facility: "",
            title: "",
            notes: "",
            amount: 0.0,
            rate: 0.0,
            status: LegacyWorklistLedgerStatus.draft
        )
    }
}
