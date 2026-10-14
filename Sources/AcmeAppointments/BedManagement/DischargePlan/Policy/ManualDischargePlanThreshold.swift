import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a manual discharge plan threshold is in its life cycle.
    enum ManualDischargePlanThresholdStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A manual discharge plan threshold. Its code is unique within a tenant.
    final class ManualDischargePlanThreshold {
        var code: String
        var label: String
        var amount: Double
        var contactEmail: String
        var diagnosisCode: String
        var category: String
        var bed: String
        var visitMinutes: Int
        var status: ManualDischargePlanThresholdStatus

        init(code: String, label: String, amount: Double, contactEmail: String, diagnosisCode: String, category: String, bed: String, visitMinutes: Int, status: ManualDischargePlanThresholdStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.contactEmail = contactEmail
            self.diagnosisCode = diagnosisCode
            self.category = category
            self.bed = bed
            self.visitMinutes = visitMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualDischargePlanThresholdStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == ManualDischargePlanThresholdStatus.cancelled
            case .inProgress:
                return next == ManualDischargePlanThresholdStatus.completed || next == ManualDischargePlanThresholdStatus.cancelled
            case .completed:
                return next == ManualDischargePlanThresholdStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualDischargePlanThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual discharge plan threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedLoad() -> Double {
            return ((amount - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ManualDischargePlanThreshold {
            return ManualDischargePlanThreshold(
                code: code,
                label: label,
                amount: amount,
                contactEmail: contactEmail,
                diagnosisCode: diagnosisCode,
                category: category,
                bed: bed,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a manual discharge plan threshold in status planned.
    static func newManualDischargePlanThreshold(_ code: String, label: String) -> ManualDischargePlanThreshold {
        return ManualDischargePlanThreshold(
            code: code,
            label: label,
            amount: 0.0,
            contactEmail: "",
            diagnosisCode: "",
            category: "",
            bed: "",
            visitMinutes: 0,
            status: ManualDischargePlanThresholdStatus.planned
        )
    }
}
