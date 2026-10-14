import AcmePlatform
import Foundation

extension Staffing {
    /// Where a manual acuity plan reservation is in its life cycle.
    enum ManualAcuityPlanReservationStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a manual acuity plan reservation and its current status.
    final class ManualAcuityPlanReservation {
        var code: String
        var label: String
        var discount: Double
        var maximum: Double
        var durationMinutes: Int
        var threshold: Double
        var startsAt: Int
        var name: String
        var category: String
        var status: ManualAcuityPlanReservationStatus

        init(code: String, label: String, discount: Double, maximum: Double, durationMinutes: Int, threshold: Double, startsAt: Int, name: String, category: String, status: ManualAcuityPlanReservationStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.maximum = maximum
            self.durationMinutes = durationMinutes
            self.threshold = threshold
            self.startsAt = startsAt
            self.name = name
            self.category = category
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualAcuityPlanReservationStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ManualAcuityPlanReservationStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ManualAcuityPlanReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual acuity plan reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedValue() -> Double {
            return ((Double(startsAt) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> ManualAcuityPlanReservation {
            return ManualAcuityPlanReservation(
                code: code,
                label: label,
                discount: discount,
                maximum: maximum,
                durationMinutes: durationMinutes,
                threshold: threshold,
                startsAt: startsAt,
                name: name,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a manual acuity plan reservation in status idle.
    static func newManualAcuityPlanReservation(_ code: String, label: String) -> ManualAcuityPlanReservation {
        return ManualAcuityPlanReservation(
            code: code,
            label: label,
            discount: 0.0,
            maximum: 0.0,
            durationMinutes: 0,
            threshold: 0.0,
            startsAt: 0,
            name: "",
            category: "",
            status: ManualAcuityPlanReservationStatus.idle
        )
    }
}
