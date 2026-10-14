import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach override is in its life cycle.
    enum OutreachOverrideStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a outreach override and its current status.
    final class OutreachOverride {
        var code: String
        var title: String
        var startsAt: Int
        var unit: String
        var discount: Double
        var acuity: Int
        var visitMinutes: Int
        var approved: Bool
        var label: String
        var minimum: Double
        var threshold: Double
        var status: OutreachOverrideStatus

        init(code: String, title: String, startsAt: Int, unit: String, discount: Double, acuity: Int, visitMinutes: Int, approved: Bool, label: String, minimum: Double, threshold: Double, status: OutreachOverrideStatus) {
            self.code = code
            self.title = title
            self.startsAt = startsAt
            self.unit = unit
            self.discount = discount
            self.acuity = acuity
            self.visitMinutes = visitMinutes
            self.approved = approved
            self.label = label
            self.minimum = minimum
            self.threshold = threshold
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OutreachOverrideStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == OutreachOverrideStatus.rejected
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: OutreachOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(title)"
        }

        func projectedExposure() -> Double {
            return (Double(acuity) * discount * 100).rounded() / 100
        }

        func copyValue() -> OutreachOverride {
            return OutreachOverride(
                code: code,
                title: title,
                startsAt: startsAt,
                unit: unit,
                discount: discount,
                acuity: acuity,
                visitMinutes: visitMinutes,
                approved: approved,
                label: label,
                minimum: minimum,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a outreach override in status proposed.
    static func newOutreachOverride(_ code: String, title: String) -> OutreachOverride {
        return OutreachOverride(
            code: code,
            title: title,
            startsAt: 0,
            unit: "",
            discount: 0.0,
            acuity: 0,
            visitMinutes: 0,
            approved: false,
            label: "",
            minimum: 0.0,
            threshold: 0.0,
            status: OutreachOverrideStatus.proposed
        )
    }
}
