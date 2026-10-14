import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a capped order set plan is in its life cycle.
    enum CappedOrderSetPlanStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a capped order set plan and its current status.
    final class CappedOrderSetPlan {
        var code: String
        var label: String
        var allergy: String
        var channel: String
        var floorValue: Double
        var approved: Bool
        var timezone: String
        var bed: String
        var contactEmail: String
        var margin: Double
        var status: CappedOrderSetPlanStatus

        init(code: String, label: String, allergy: String, channel: String, floorValue: Double, approved: Bool, timezone: String, bed: String, contactEmail: String, margin: Double, status: CappedOrderSetPlanStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.channel = channel
            self.floorValue = floorValue
            self.approved = approved
            self.timezone = timezone
            self.bed = bed
            self.contactEmail = contactEmail
            self.margin = margin
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

        func canMoveTo(_ next: CappedOrderSetPlanStatus) -> Bool {
            switch status {
            case .new:
                return next == CappedOrderSetPlanStatus.failed
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == CappedOrderSetPlanStatus.done
            case .done:
                return next == CappedOrderSetPlanStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedOrderSetPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped order set plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netExposure() -> Double {
            return ((floorValue - margin) * 100).rounded() / 100
        }

        func copyValue() -> CappedOrderSetPlan {
            return CappedOrderSetPlan(
                code: code,
                label: label,
                allergy: allergy,
                channel: channel,
                floorValue: floorValue,
                approved: approved,
                timezone: timezone,
                bed: bed,
                contactEmail: contactEmail,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a capped order set plan in status new.
    static func newCappedOrderSetPlan(_ code: String, label: String) -> CappedOrderSetPlan {
        return CappedOrderSetPlan(
            code: code,
            label: label,
            allergy: "",
            channel: "",
            floorValue: 0.0,
            approved: false,
            timezone: "",
            bed: "",
            contactEmail: "",
            margin: 0.0,
            status: CappedOrderSetPlanStatus.new
        )
    }
}
