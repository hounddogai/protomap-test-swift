import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling worklist adjustment is in its life cycle.
    enum RollingWorklistAdjustmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a rolling worklist adjustment and its current status.
    final class RollingWorklistAdjustment {
        var code: String
        var title: String
        var copay: Double
        var contactEmail: String
        var bed: String
        var discount: Double
        var threshold: Double
        var quantity: Int
        var unit: String
        var reviewer: String
        var facility: String
        var status: RollingWorklistAdjustmentStatus

        init(code: String, title: String, copay: Double, contactEmail: String, bed: String, discount: Double, threshold: Double, quantity: Int, unit: String, reviewer: String, facility: String, status: RollingWorklistAdjustmentStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.contactEmail = contactEmail
            self.bed = bed
            self.discount = discount
            self.threshold = threshold
            self.quantity = quantity
            self.unit = unit
            self.reviewer = reviewer
            self.facility = facility
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

        func canMoveTo(_ next: RollingWorklistAdjustmentStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == RollingWorklistAdjustmentStatus.ready || next == RollingWorklistAdjustmentStatus.draining
            case .ready:
                return next == RollingWorklistAdjustmentStatus.stopped
            case .draining:
                return next == RollingWorklistAdjustmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingWorklistAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling worklist adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedValue() -> Double {
            return ((discount + copay) * 100).rounded() / 100
        }

        func copyValue() -> RollingWorklistAdjustment {
            return RollingWorklistAdjustment(
                code: code,
                title: title,
                copay: copay,
                contactEmail: contactEmail,
                bed: bed,
                discount: discount,
                threshold: threshold,
                quantity: quantity,
                unit: unit,
                reviewer: reviewer,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a rolling worklist adjustment in status idle.
    static func newRollingWorklistAdjustment(_ code: String, title: String) -> RollingWorklistAdjustment {
        return RollingWorklistAdjustment(
            code: code,
            title: title,
            copay: 0.0,
            contactEmail: "",
            bed: "",
            discount: 0.0,
            threshold: 0.0,
            quantity: 0,
            unit: "",
            reviewer: "",
            facility: "",
            status: RollingWorklistAdjustmentStatus.idle
        )
    }
}
