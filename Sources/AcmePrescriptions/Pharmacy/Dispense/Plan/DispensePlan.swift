import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense plan is in its life cycle.
    enum DispensePlanStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One dispense plan, with what the planners need to act on it.
    final class DispensePlan {
        var code: String
        var title: String
        var segment: String
        var label: String
        var weight: Double
        var currency: String
        var acuity: Int
        var summary: String
        var createdAt: Int
        var status: DispensePlanStatus

        init(code: String, title: String, segment: String, label: String, weight: Double, currency: String, acuity: Int, summary: String, createdAt: Int, status: DispensePlanStatus) {
            self.code = code
            self.title = title
            self.segment = segment
            self.label = label
            self.weight = weight
            self.currency = currency
            self.acuity = acuity
            self.summary = summary
            self.createdAt = createdAt
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

        func canMoveTo(_ next: DispensePlanStatus) -> Bool {
            switch status {
            case .idle:
                return next == DispensePlanStatus.ready || next == DispensePlanStatus.draining
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == DispensePlanStatus.draining
            case .draining:
                return next == DispensePlanStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DispensePlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveExposure() -> Double {
            return (weight * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> DispensePlan {
            return DispensePlan(
                code: code,
                title: title,
                segment: segment,
                label: label,
                weight: weight,
                currency: currency,
                acuity: acuity,
                summary: summary,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a dispense plan in status idle.
    static func newDispensePlan(_ code: String, title: String) -> DispensePlan {
        return DispensePlan(
            code: code,
            title: title,
            segment: "",
            label: "",
            weight: 0.0,
            currency: "",
            acuity: 0,
            summary: "",
            createdAt: 0,
            status: DispensePlanStatus.idle
        )
    }
}
