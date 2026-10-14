import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert preference is in its life cycle.
    enum AlertPreferenceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A alert preference as the alert team keeps it.
    final class AlertPreference {
        var code: String
        var label: String
        var timezone: String
        var region: String
        var quantity: Int
        var phone: String
        var batchSize: Int
        var startsAt: Int
        var status: AlertPreferenceStatus

        init(code: String, label: String, timezone: String, region: String, quantity: Int, phone: String, batchSize: Int, startsAt: Int, status: AlertPreferenceStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.region = region
            self.quantity = quantity
            self.phone = phone
            self.batchSize = batchSize
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AlertPreferenceStatus) -> Bool {
            switch status {
            case .requested:
                return next == AlertPreferenceStatus.granted
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == AlertPreferenceStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AlertPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveExposure() -> Double {
            return (Double(quantity) * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> AlertPreference {
            return AlertPreference(
                code: code,
                label: label,
                timezone: timezone,
                region: region,
                quantity: quantity,
                phone: phone,
                batchSize: batchSize,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a alert preference in status requested.
    static func newAlertPreference(_ code: String, label: String) -> AlertPreference {
        return AlertPreference(
            code: code,
            label: label,
            timezone: "",
            region: "",
            quantity: 0,
            phone: "",
            batchSize: 0,
            startsAt: 0,
            status: AlertPreferenceStatus.requested
        )
    }
}
