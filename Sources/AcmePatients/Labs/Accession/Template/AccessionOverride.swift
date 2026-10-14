import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession override is in its life cycle.
    enum AccessionOverrideStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A accession override. Its code is unique within a tenant.
    final class AccessionOverride {
        var code: String
        var title: String
        var amount: Double
        var timezone: String
        var refills: Int
        var copay: Double
        var acuity: Int
        var minimum: Double
        var status: AccessionOverrideStatus

        init(code: String, title: String, amount: Double, timezone: String, refills: Int, copay: Double, acuity: Int, minimum: Double, status: AccessionOverrideStatus) {
            self.code = code
            self.title = title
            self.amount = amount
            self.timezone = timezone
            self.refills = refills
            self.copay = copay
            self.acuity = acuity
            self.minimum = minimum
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

        func canMoveTo(_ next: AccessionOverrideStatus) -> Bool {
            switch status {
            case .planned:
                return next == AccessionOverrideStatus.cancelled
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == AccessionOverrideStatus.completed || next == AccessionOverrideStatus.cancelled
            case .completed:
                return next == AccessionOverrideStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedValue() -> Double {
            return ((Double(refills) - copay) * 100).rounded() / 100
        }

        func copyValue() -> AccessionOverride {
            return AccessionOverride(
                code: code,
                title: title,
                amount: amount,
                timezone: timezone,
                refills: refills,
                copay: copay,
                acuity: acuity,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a accession override in status planned.
    static func newAccessionOverride(_ code: String, title: String) -> AccessionOverride {
        return AccessionOverride(
            code: code,
            title: title,
            amount: 0.0,
            timezone: "",
            refills: 0,
            copay: 0.0,
            acuity: 0,
            minimum: 0.0,
            status: AccessionOverrideStatus.planned
        )
    }
}
