import AcmePlatform
import Foundation

extension Staffing {
    /// Where a regional acuity plan reservation is in its life cycle.
    enum RegionalAcuityPlanReservationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One regional acuity plan reservation, with what the planners need to act on it.
    final class RegionalAcuityPlanReservation {
        var code: String
        var label: String
        var ceiling: Double
        var rate: Double
        var description: String
        var approved: Bool
        var currency: String
        var status: RegionalAcuityPlanReservationStatus

        init(code: String, label: String, ceiling: Double, rate: Double, description: String, approved: Bool, currency: String, status: RegionalAcuityPlanReservationStatus) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.rate = rate
            self.description = description
            self.approved = approved
            self.currency = currency
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

        func canMoveTo(_ next: RegionalAcuityPlanReservationStatus) -> Bool {
            switch status {
            case .draft:
                return next == RegionalAcuityPlanReservationStatus.closed
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == RegionalAcuityPlanReservationStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalAcuityPlanReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional acuity plan reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedVolume() -> Double {
            return ((rate + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> RegionalAcuityPlanReservation {
            return RegionalAcuityPlanReservation(
                code: code,
                label: label,
                ceiling: ceiling,
                rate: rate,
                description: description,
                approved: approved,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional acuity plan reservation in status draft.
    static func newRegionalAcuityPlanReservation(_ code: String, label: String) -> RegionalAcuityPlanReservation {
        return RegionalAcuityPlanReservation(
            code: code,
            label: label,
            ceiling: 0.0,
            rate: 0.0,
            description: "",
            approved: false,
            currency: "",
            status: RegionalAcuityPlanReservationStatus.draft
        )
    }
}
