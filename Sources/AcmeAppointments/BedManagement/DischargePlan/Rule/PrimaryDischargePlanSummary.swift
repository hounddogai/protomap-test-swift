import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a primary discharge plan summary is in its life cycle.
    enum PrimaryDischargePlanSummaryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A primary discharge plan summary as the discharge plan team keeps it.
    final class PrimaryDischargePlanSummary {
        var code: String
        var title: String
        var threshold: Double
        var floorValue: Double
        var allergy: String
        var copay: Double
        var unit: String
        var archived: Bool
        var retries: Int
        var status: PrimaryDischargePlanSummaryStatus

        init(code: String, title: String, threshold: Double, floorValue: Double, allergy: String, copay: Double, unit: String, archived: Bool, retries: Int, status: PrimaryDischargePlanSummaryStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.floorValue = floorValue
            self.allergy = allergy
            self.copay = copay
            self.unit = unit
            self.archived = archived
            self.retries = retries
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

        func canMoveTo(_ next: PrimaryDischargePlanSummaryStatus) -> Bool {
            switch status {
            case .new:
                return next == PrimaryDischargePlanSummaryStatus.queued || next == PrimaryDischargePlanSummaryStatus.done
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == PrimaryDischargePlanSummaryStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryDischargePlanSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary discharge plan summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedLoad() -> Double {
            return (copay * floorValue * 100).rounded() / 100
        }

        func copyValue() -> PrimaryDischargePlanSummary {
            return PrimaryDischargePlanSummary(
                code: code,
                title: title,
                threshold: threshold,
                floorValue: floorValue,
                allergy: allergy,
                copay: copay,
                unit: unit,
                archived: archived,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a primary discharge plan summary in status new.
    static func newPrimaryDischargePlanSummary(_ code: String, title: String) -> PrimaryDischargePlanSummary {
        return PrimaryDischargePlanSummary(
            code: code,
            title: title,
            threshold: 0.0,
            floorValue: 0.0,
            allergy: "",
            copay: 0.0,
            unit: "",
            archived: false,
            retries: 0,
            status: PrimaryDischargePlanSummaryStatus.new
        )
    }
}
