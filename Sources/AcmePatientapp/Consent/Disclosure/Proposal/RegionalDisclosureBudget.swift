import AcmePlatform
import Foundation

extension Consent {
    /// Where a regional disclosure budget is in its life cycle.
    enum RegionalDisclosureBudgetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a regional disclosure budget and its current status.
    final class RegionalDisclosureBudget {
        var code: String
        var title: String
        var cost: Double
        var startsAt: Int
        var ownerID: String
        var budget: Double
        var encounterID: String
        var visible: Bool
        var diagnosisCode: String
        var status: RegionalDisclosureBudgetStatus

        init(code: String, title: String, cost: Double, startsAt: Int, ownerID: String, budget: Double, encounterID: String, visible: Bool, diagnosisCode: String, status: RegionalDisclosureBudgetStatus) {
            self.code = code
            self.title = title
            self.cost = cost
            self.startsAt = startsAt
            self.ownerID = ownerID
            self.budget = budget
            self.encounterID = encounterID
            self.visible = visible
            self.diagnosisCode = diagnosisCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalDisclosureBudgetStatus) -> Bool {
            switch status {
            case .new:
                return next == RegionalDisclosureBudgetStatus.running || next == RegionalDisclosureBudgetStatus.done
            case .queued:
                return next == RegionalDisclosureBudgetStatus.done
            case .running:
                return next == RegionalDisclosureBudgetStatus.done || next == RegionalDisclosureBudgetStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: RegionalDisclosureBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional disclosure budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("regional disclosure budget") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((Double(startsAt) - budget) * 100).rounded() / 100
        }

        func copyValue() -> RegionalDisclosureBudget {
            return RegionalDisclosureBudget(
                code: code,
                title: title,
                cost: cost,
                startsAt: startsAt,
                ownerID: ownerID,
                budget: budget,
                encounterID: encounterID,
                visible: visible,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional disclosure budget in status new.
    static func newRegionalDisclosureBudget(_ code: String, title: String) -> RegionalDisclosureBudget {
        return RegionalDisclosureBudget(
            code: code,
            title: title,
            cost: 0.0,
            startsAt: 0,
            ownerID: "",
            budget: 0.0,
            encounterID: "",
            visible: false,
            diagnosisCode: "",
            status: RegionalDisclosureBudgetStatus.new
        )
    }
}
