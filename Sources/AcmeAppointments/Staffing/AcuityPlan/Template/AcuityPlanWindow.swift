import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan window is in its life cycle.
    enum AcuityPlanWindowStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A acuity plan window as the acuity plan team keeps it.
    final class AcuityPlanWindow {
        var code: String
        var name: String
        var copay: Double
        var locale: String
        var label: String
        var expiresAt: Int
        var contactEmail: String
        var channel: String
        var timezone: String
        var description: String
        var status: AcuityPlanWindowStatus

        init(code: String, name: String, copay: Double, locale: String, label: String, expiresAt: Int, contactEmail: String, channel: String, timezone: String, description: String, status: AcuityPlanWindowStatus) {
            self.code = code
            self.name = name
            self.copay = copay
            self.locale = locale
            self.label = label
            self.expiresAt = expiresAt
            self.contactEmail = contactEmail
            self.channel = channel
            self.timezone = timezone
            self.description = description
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

        func canMoveTo(_ next: AcuityPlanWindowStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AcuityPlanWindowStatus.rejected
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == AcuityPlanWindowStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AcuityPlanWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func projectedLoad() -> Double {
            return (Double(expiresAt) * copay * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanWindow {
            return AcuityPlanWindow(
                code: code,
                name: name,
                copay: copay,
                locale: locale,
                label: label,
                expiresAt: expiresAt,
                contactEmail: contactEmail,
                channel: channel,
                timezone: timezone,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a acuity plan window in status proposed.
    static func newAcuityPlanWindow(_ code: String, name: String) -> AcuityPlanWindow {
        return AcuityPlanWindow(
            code: code,
            name: name,
            copay: 0.0,
            locale: "",
            label: "",
            expiresAt: 0,
            contactEmail: "",
            channel: "",
            timezone: "",
            description: "",
            status: AcuityPlanWindowStatus.proposed
        )
    }
}
