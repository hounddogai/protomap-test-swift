import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality plan is in its life cycle.
    enum ModalityPlanStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a modality plan and its current status.
    final class ModalityPlan {
        var code: String
        var title: String
        var timezone: String
        var refills: Int
        var bed: String
        var facility: String
        var rate: Double
        var status: ModalityPlanStatus

        init(code: String, title: String, timezone: String, refills: Int, bed: String, facility: String, rate: Double, status: ModalityPlanStatus) {
            self.code = code
            self.title = title
            self.timezone = timezone
            self.refills = refills
            self.bed = bed
            self.facility = facility
            self.rate = rate
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

        func canMoveTo(_ next: ModalityPlanStatus) -> Bool {
            switch status {
            case .idle:
                return next == ModalityPlanStatus.warming || next == ModalityPlanStatus.stopped
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ModalityPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedTotal() -> Double {
            return (rate * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> ModalityPlan {
            return ModalityPlan(
                code: code,
                title: title,
                timezone: timezone,
                refills: refills,
                bed: bed,
                facility: facility,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a modality plan in status idle.
    static func newModalityPlan(_ code: String, title: String) -> ModalityPlan {
        return ModalityPlan(
            code: code,
            title: title,
            timezone: "",
            refills: 0,
            bed: "",
            facility: "",
            rate: 0.0,
            status: ModalityPlanStatus.idle
        )
    }
}
