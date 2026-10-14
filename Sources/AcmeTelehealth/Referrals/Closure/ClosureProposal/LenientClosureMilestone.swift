import AcmePlatform
import Foundation

extension Referrals {
    /// Where a lenient closure milestone is in its life cycle.
    enum LenientClosureMilestoneStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A lenient closure milestone as the closure team keeps it.
    final class LenientClosureMilestone {
        var code: String
        var title: String
        var unit: String
        var quantity: Int
        var startsAt: Int
        var region: String
        var acuity: Int
        var threshold: Double
        var facility: String
        var ward: String
        var status: LenientClosureMilestoneStatus

        init(code: String, title: String, unit: String, quantity: Int, startsAt: Int, region: String, acuity: Int, threshold: Double, facility: String, ward: String, status: LenientClosureMilestoneStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.quantity = quantity
            self.startsAt = startsAt
            self.region = region
            self.acuity = acuity
            self.threshold = threshold
            self.facility = facility
            self.ward = ward
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

        func canMoveTo(_ next: LenientClosureMilestoneStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == LenientClosureMilestoneStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientClosureMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient closure milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedLoad() -> Double {
            return ((Double(quantity) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> LenientClosureMilestone {
            return LenientClosureMilestone(
                code: code,
                title: title,
                unit: unit,
                quantity: quantity,
                startsAt: startsAt,
                region: region,
                acuity: acuity,
                threshold: threshold,
                facility: facility,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a lenient closure milestone in status created.
    static func newLenientClosureMilestone(_ code: String, title: String) -> LenientClosureMilestone {
        return LenientClosureMilestone(
            code: code,
            title: title,
            unit: "",
            quantity: 0,
            startsAt: 0,
            region: "",
            acuity: 0,
            threshold: 0.0,
            facility: "",
            ward: "",
            status: LenientClosureMilestoneStatus.created
        )
    }
}
