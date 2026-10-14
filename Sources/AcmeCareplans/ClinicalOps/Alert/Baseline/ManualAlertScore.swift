import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a manual alert score is in its life cycle.
    enum ManualAlertScoreStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A manual alert score as the alert team keeps it.
    final class ManualAlertScore {
        var code: String
        var label: String
        var active: Bool
        var pinned: Bool
        var country: String
        var facility: String
        var batchSize: Int
        var locale: String
        var margin: Double
        var name: String
        var channel: String
        var status: ManualAlertScoreStatus

        init(code: String, label: String, active: Bool, pinned: Bool, country: String, facility: String, batchSize: Int, locale: String, margin: Double, name: String, channel: String, status: ManualAlertScoreStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.pinned = pinned
            self.country = country
            self.facility = facility
            self.batchSize = batchSize
            self.locale = locale
            self.margin = margin
            self.name = name
            self.channel = channel
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

        func canMoveTo(_ next: ManualAlertScoreStatus) -> Bool {
            switch status {
            case .requested:
                return next == ManualAlertScoreStatus.granted
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: ManualAlertScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual alert score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedVolume() -> Double {
            return ((Double(batchSize) + margin) * 100).rounded() / 100
        }

        func copyValue() -> ManualAlertScore {
            return ManualAlertScore(
                code: code,
                label: label,
                active: active,
                pinned: pinned,
                country: country,
                facility: facility,
                batchSize: batchSize,
                locale: locale,
                margin: margin,
                name: name,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a manual alert score in status requested.
    static func newManualAlertScore(_ code: String, label: String) -> ManualAlertScore {
        return ManualAlertScore(
            code: code,
            label: label,
            active: false,
            pinned: false,
            country: "",
            facility: "",
            batchSize: 0,
            locale: "",
            margin: 0.0,
            name: "",
            channel: "",
            status: ManualAlertScoreStatus.requested
        )
    }
}
