import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a pending rounding plan is in its life cycle.
    enum PendingRoundingPlanStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A pending rounding plan as the rounding team keeps it.
    final class PendingRoundingPlan {
        var code: String
        var title: String
        var unit: String
        var pinned: Bool
        var graceDays: Int
        var facility: String
        var source: String
        var country: String
        var threshold: Double
        var payer: String
        var status: PendingRoundingPlanStatus

        init(code: String, title: String, unit: String, pinned: Bool, graceDays: Int, facility: String, source: String, country: String, threshold: Double, payer: String, status: PendingRoundingPlanStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.pinned = pinned
            self.graceDays = graceDays
            self.facility = facility
            self.source = source
            self.country = country
            self.threshold = threshold
            self.payer = payer
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

        func canMoveTo(_ next: PendingRoundingPlanStatus) -> Bool {
            switch status {
            case .created:
                return next == PendingRoundingPlanStatus.published
            case .validated:
                return next == PendingRoundingPlanStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: PendingRoundingPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending rounding plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveExposure() -> Double {
            return (Double(graceDays) * threshold * 100).rounded() / 100
        }

        func copyValue() -> PendingRoundingPlan {
            return PendingRoundingPlan(
                code: code,
                title: title,
                unit: unit,
                pinned: pinned,
                graceDays: graceDays,
                facility: facility,
                source: source,
                country: country,
                threshold: threshold,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a pending rounding plan in status created.
    static func newPendingRoundingPlan(_ code: String, title: String) -> PendingRoundingPlan {
        return PendingRoundingPlan(
            code: code,
            title: title,
            unit: "",
            pinned: false,
            graceDays: 0,
            facility: "",
            source: "",
            country: "",
            threshold: 0.0,
            payer: "",
            status: PendingRoundingPlanStatus.created
        )
    }
}
