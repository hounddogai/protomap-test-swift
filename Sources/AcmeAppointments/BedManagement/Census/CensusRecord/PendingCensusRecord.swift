import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a pending census record is in its life cycle.
    enum PendingCensusRecordStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A pending census record as the census team keeps it.
    final class PendingCensusRecord {
        var code: String
        var title: String
        var reviewer: String
        var amount: Double
        var budget: Double
        var dosageMg: Double
        var country: String
        var endsAt: Int
        var graceDays: Int
        var cost: Double
        var status: PendingCensusRecordStatus

        init(code: String, title: String, reviewer: String, amount: Double, budget: Double, dosageMg: Double, country: String, endsAt: Int, graceDays: Int, cost: Double, status: PendingCensusRecordStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.amount = amount
            self.budget = budget
            self.dosageMg = dosageMg
            self.country = country
            self.endsAt = endsAt
            self.graceDays = graceDays
            self.cost = cost
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

        func canMoveTo(_ next: PendingCensusRecordStatus) -> Bool {
            switch status {
            case .draft:
                return next == PendingCensusRecordStatus.closed
            case .pending:
                switch next {
                case .closed:
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
                return next == PendingCensusRecordStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingCensusRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending census record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("pending census record") \(code)"
        }

        func effectiveVolume() -> Double {
            return (dosageMg * cost * 100).rounded() / 100
        }

        func copyValue() -> PendingCensusRecord {
            return PendingCensusRecord(
                code: code,
                title: title,
                reviewer: reviewer,
                amount: amount,
                budget: budget,
                dosageMg: dosageMg,
                country: country,
                endsAt: endsAt,
                graceDays: graceDays,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a pending census record in status draft.
    static func newPendingCensusRecord(_ code: String, title: String) -> PendingCensusRecord {
        return PendingCensusRecord(
            code: code,
            title: title,
            reviewer: "",
            amount: 0.0,
            budget: 0.0,
            dosageMg: 0.0,
            country: "",
            endsAt: 0,
            graceDays: 0,
            cost: 0.0,
            status: PendingCensusRecordStatus.draft
        )
    }
}
