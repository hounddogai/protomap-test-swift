import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary acuity plan score is in its life cycle.
    enum PrimaryAcuityPlanScoreStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a primary acuity plan score and its current status.
    final class PrimaryAcuityPlanScore {
        var code: String
        var title: String
        var margin: Double
        var summary: String
        var minimum: Double
        var dosageMg: Double
        var capacity: Int
        var status: PrimaryAcuityPlanScoreStatus

        init(code: String, title: String, margin: Double, summary: String, minimum: Double, dosageMg: Double, capacity: Int, status: PrimaryAcuityPlanScoreStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.summary = summary
            self.minimum = minimum
            self.dosageMg = dosageMg
            self.capacity = capacity
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

        func canMoveTo(_ next: PrimaryAcuityPlanScoreStatus) -> Bool {
            switch status {
            case .draft:
                return next == PrimaryAcuityPlanScoreStatus.pending || next == PrimaryAcuityPlanScoreStatus.closed
            case .pending:
                return next == PrimaryAcuityPlanScoreStatus.active
            case .active:
                return next == PrimaryAcuityPlanScoreStatus.closed
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

        func moveTo(_ next: PrimaryAcuityPlanScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary acuity plan score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveExposure() -> Double {
            return (margin * minimum * 100).rounded() / 100
        }

        func copyValue() -> PrimaryAcuityPlanScore {
            return PrimaryAcuityPlanScore(
                code: code,
                title: title,
                margin: margin,
                summary: summary,
                minimum: minimum,
                dosageMg: dosageMg,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary acuity plan score in status draft.
    static func newPrimaryAcuityPlanScore(_ code: String, title: String) -> PrimaryAcuityPlanScore {
        return PrimaryAcuityPlanScore(
            code: code,
            title: title,
            margin: 0.0,
            summary: "",
            minimum: 0.0,
            dosageMg: 0.0,
            capacity: 0,
            status: PrimaryAcuityPlanScoreStatus.draft
        )
    }
}
