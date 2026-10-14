import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan estimate is in its life cycle.
    enum DischargePlanEstimateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A discharge plan estimate as the discharge plan team keeps it.
    final class DischargePlanEstimate {
        var code: String
        var label: String
        var title: String
        var active: Bool
        var category: String
        var score: Double
        var endsAt: Int
        var externalRef: String
        var visitMinutes: Int
        var phone: String
        var status: DischargePlanEstimateStatus

        init(code: String, label: String, title: String, active: Bool, category: String, score: Double, endsAt: Int, externalRef: String, visitMinutes: Int, phone: String, status: DischargePlanEstimateStatus) {
            self.code = code
            self.label = label
            self.title = title
            self.active = active
            self.category = category
            self.score = score
            self.endsAt = endsAt
            self.externalRef = externalRef
            self.visitMinutes = visitMinutes
            self.phone = phone
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

        func canMoveTo(_ next: DischargePlanEstimateStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == DischargePlanEstimateStatus.inProgress || next == DischargePlanEstimateStatus.cancelled
            case .inProgress:
                return next == DischargePlanEstimateStatus.completed || next == DischargePlanEstimateStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: DischargePlanEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedExposure() -> Double {
            return ((Double(endsAt) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanEstimate {
            return DischargePlanEstimate(
                code: code,
                label: label,
                title: title,
                active: active,
                category: category,
                score: score,
                endsAt: endsAt,
                externalRef: externalRef,
                visitMinutes: visitMinutes,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a discharge plan estimate in status planned.
    static func newDischargePlanEstimate(_ code: String, label: String) -> DischargePlanEstimate {
        return DischargePlanEstimate(
            code: code,
            label: label,
            title: "",
            active: false,
            category: "",
            score: 0.0,
            endsAt: 0,
            externalRef: "",
            visitMinutes: 0,
            phone: "",
            status: DischargePlanEstimateStatus.planned
        )
    }
}
