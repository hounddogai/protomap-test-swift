import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a seasonal charge estimate is in its life cycle.
    enum SeasonalChargeEstimateStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One seasonal charge estimate, with what the planners need to act on it.
    final class SeasonalChargeEstimate {
        var code: String
        var name: String
        var diagnosisCode: String
        var priority: Int
        var windowDays: Int
        var clinicianID: String
        var archived: Bool
        var visible: Bool
        var cost: Double
        var title: String
        var bed: String
        var status: SeasonalChargeEstimateStatus

        init(code: String, name: String, diagnosisCode: String, priority: Int, windowDays: Int, clinicianID: String, archived: Bool, visible: Bool, cost: Double, title: String, bed: String, status: SeasonalChargeEstimateStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.priority = priority
            self.windowDays = windowDays
            self.clinicianID = clinicianID
            self.archived = archived
            self.visible = visible
            self.cost = cost
            self.title = title
            self.bed = bed
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalChargeEstimateStatus) -> Bool {
            switch status {
            case .created:
                return next == SeasonalChargeEstimateStatus.validated
            case .validated:
                return next == SeasonalChargeEstimateStatus.published || next == SeasonalChargeEstimateStatus.retired
            case .published:
                return next == SeasonalChargeEstimateStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalChargeEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal charge estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveVolume() -> Double {
            return ((Double(priority) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalChargeEstimate {
            return SeasonalChargeEstimate(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                priority: priority,
                windowDays: windowDays,
                clinicianID: clinicianID,
                archived: archived,
                visible: visible,
                cost: cost,
                title: title,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal charge estimate in status created.
    static func newSeasonalChargeEstimate(_ code: String, name: String) -> SeasonalChargeEstimate {
        return SeasonalChargeEstimate(
            code: code,
            name: name,
            diagnosisCode: "",
            priority: 0,
            windowDays: 0,
            clinicianID: "",
            archived: false,
            visible: false,
            cost: 0.0,
            title: "",
            bed: "",
            status: SeasonalChargeEstimateStatus.created
        )
    }
}
