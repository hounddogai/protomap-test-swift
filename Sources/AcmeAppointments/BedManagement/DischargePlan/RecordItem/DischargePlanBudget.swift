import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan budget is in its life cycle.
    enum DischargePlanBudgetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One discharge plan budget, with what the planners need to act on it.
    final class DischargePlanBudget {
        var code: String
        var title: String
        var pinned: Bool
        var ownerID: String
        var limit: Int
        var clinicianID: String
        var currency: String
        var region: String
        var checksum: String
        var margin: Double
        var retries: Int
        var status: DischargePlanBudgetStatus

        init(code: String, title: String, pinned: Bool, ownerID: String, limit: Int, clinicianID: String, currency: String, region: String, checksum: String, margin: Double, retries: Int, status: DischargePlanBudgetStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.ownerID = ownerID
            self.limit = limit
            self.clinicianID = clinicianID
            self.currency = currency
            self.region = region
            self.checksum = checksum
            self.margin = margin
            self.retries = retries
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

        func canMoveTo(_ next: DischargePlanBudgetStatus) -> Bool {
            switch status {
            case .draft:
                return next == DischargePlanBudgetStatus.pending || next == DischargePlanBudgetStatus.active
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == DischargePlanBudgetStatus.suspended
            case .suspended:
                return next == DischargePlanBudgetStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DischargePlanBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedExposure() -> Double {
            return (margin * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanBudget {
            return DischargePlanBudget(
                code: code,
                title: title,
                pinned: pinned,
                ownerID: ownerID,
                limit: limit,
                clinicianID: clinicianID,
                currency: currency,
                region: region,
                checksum: checksum,
                margin: margin,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a discharge plan budget in status draft.
    static func newDischargePlanBudget(_ code: String, title: String) -> DischargePlanBudget {
        return DischargePlanBudget(
            code: code,
            title: title,
            pinned: false,
            ownerID: "",
            limit: 0,
            clinicianID: "",
            currency: "",
            region: "",
            checksum: "",
            margin: 0.0,
            retries: 0,
            status: DischargePlanBudgetStatus.draft
        )
    }
}
