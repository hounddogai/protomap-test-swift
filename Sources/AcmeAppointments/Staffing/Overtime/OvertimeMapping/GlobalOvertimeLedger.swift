import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global overtime ledger is in its life cycle.
    enum GlobalOvertimeLedgerStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A global overtime ledger as the overtime team keeps it.
    final class GlobalOvertimeLedger {
        var code: String
        var name: String
        var clinicianID: String
        var score: Double
        var quantity: Int
        var reviewer: String
        var notes: String
        var bed: String
        var locale: String
        var status: GlobalOvertimeLedgerStatus

        init(code: String, name: String, clinicianID: String, score: Double, quantity: Int, reviewer: String, notes: String, bed: String, locale: String, status: GlobalOvertimeLedgerStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.score = score
            self.quantity = quantity
            self.reviewer = reviewer
            self.notes = notes
            self.bed = bed
            self.locale = locale
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

        func canMoveTo(_ next: GlobalOvertimeLedgerStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == GlobalOvertimeLedgerStatus.suspended || next == GlobalOvertimeLedgerStatus.closed
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

        func moveTo(_ next: GlobalOvertimeLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global overtime ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedVolume() -> Double {
            return ((score - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalOvertimeLedger {
            return GlobalOvertimeLedger(
                code: code,
                name: name,
                clinicianID: clinicianID,
                score: score,
                quantity: quantity,
                reviewer: reviewer,
                notes: notes,
                bed: bed,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a global overtime ledger in status draft.
    static func newGlobalOvertimeLedger(_ code: String, name: String) -> GlobalOvertimeLedger {
        return GlobalOvertimeLedger(
            code: code,
            name: name,
            clinicianID: "",
            score: 0.0,
            quantity: 0,
            reviewer: "",
            notes: "",
            bed: "",
            locale: "",
            status: GlobalOvertimeLedgerStatus.draft
        )
    }
}
