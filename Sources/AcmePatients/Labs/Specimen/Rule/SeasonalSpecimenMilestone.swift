import AcmePlatform
import Foundation

extension Labs {
    /// Where a seasonal specimen milestone is in its life cycle.
    enum SeasonalSpecimenMilestoneStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a seasonal specimen milestone and its current status.
    final class SeasonalSpecimenMilestone {
        var code: String
        var title: String
        var acuity: Int
        var patientRef: String
        var floorValue: Double
        var limit: Int
        var amount: Double
        var status: SeasonalSpecimenMilestoneStatus

        init(code: String, title: String, acuity: Int, patientRef: String, floorValue: Double, limit: Int, amount: Double, status: SeasonalSpecimenMilestoneStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.patientRef = patientRef
            self.floorValue = floorValue
            self.limit = limit
            self.amount = amount
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

        func canMoveTo(_ next: SeasonalSpecimenMilestoneStatus) -> Bool {
            switch status {
            case .new:
                return next == SeasonalSpecimenMilestoneStatus.running || next == SeasonalSpecimenMilestoneStatus.done
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: SeasonalSpecimenMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal specimen milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netValue() -> Double {
            return ((amount - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalSpecimenMilestone {
            return SeasonalSpecimenMilestone(
                code: code,
                title: title,
                acuity: acuity,
                patientRef: patientRef,
                floorValue: floorValue,
                limit: limit,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal specimen milestone in status new.
    static func newSeasonalSpecimenMilestone(_ code: String, title: String) -> SeasonalSpecimenMilestone {
        return SeasonalSpecimenMilestone(
            code: code,
            title: title,
            acuity: 0,
            patientRef: "",
            floorValue: 0.0,
            limit: 0,
            amount: 0.0,
            status: SeasonalSpecimenMilestoneStatus.new
        )
    }
}
