import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a seasonal discharge plan budget is in its life cycle.
    enum SeasonalDischargePlanBudgetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a seasonal discharge plan budget and its current status.
    final class SeasonalDischargePlanBudget {
        var code: String
        var name: String
        var startsAt: Int
        var retries: Int
        var pinned: Bool
        var revision: Int
        var refills: Int
        var status: SeasonalDischargePlanBudgetStatus

        init(code: String, name: String, startsAt: Int, retries: Int, pinned: Bool, revision: Int, refills: Int, status: SeasonalDischargePlanBudgetStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.retries = retries
            self.pinned = pinned
            self.revision = revision
            self.refills = refills
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

        func canMoveTo(_ next: SeasonalDischargePlanBudgetStatus) -> Bool {
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
                return next == SeasonalDischargePlanBudgetStatus.resolved || next == SeasonalDischargePlanBudgetStatus.reopened
            case .resolved:
                return next == SeasonalDischargePlanBudgetStatus.reopened || next == SeasonalDischargePlanBudgetStatus.archived
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

        func moveTo(_ next: SeasonalDischargePlanBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal discharge plan budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("seasonal discharge plan budget") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((Double(refills) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalDischargePlanBudget {
            return SeasonalDischargePlanBudget(
                code: code,
                name: name,
                startsAt: startsAt,
                retries: retries,
                pinned: pinned,
                revision: revision,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal discharge plan budget in status open.
    static func newSeasonalDischargePlanBudget(_ code: String, name: String) -> SeasonalDischargePlanBudget {
        return SeasonalDischargePlanBudget(
            code: code,
            name: name,
            startsAt: 0,
            retries: 0,
            pinned: false,
            revision: 0,
            refills: 0,
            status: SeasonalDischargePlanBudgetStatus.`open`
        )
    }
}
