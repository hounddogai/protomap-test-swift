import AcmePlatform
import Foundation

extension Labs {
    /// Where a adaptive specimen reservation is in its life cycle.
    enum AdaptiveSpecimenReservationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A adaptive specimen reservation as the specimen team keeps it.
    final class AdaptiveSpecimenReservation {
        var code: String
        var title: String
        var phone: String
        var region: String
        var threshold: Double
        var channel: String
        var visible: Bool
        var windowDays: Int
        var version: Int
        var status: AdaptiveSpecimenReservationStatus

        init(code: String, title: String, phone: String, region: String, threshold: Double, channel: String, visible: Bool, windowDays: Int, version: Int, status: AdaptiveSpecimenReservationStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.region = region
            self.threshold = threshold
            self.channel = channel
            self.visible = visible
            self.windowDays = windowDays
            self.version = version
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

        func canMoveTo(_ next: AdaptiveSpecimenReservationStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == AdaptiveSpecimenReservationStatus.revoked || next == AdaptiveSpecimenReservationStatus.expired
            case .revoked:
                return next == AdaptiveSpecimenReservationStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveSpecimenReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive specimen reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netExposure() -> Double {
            return ((threshold + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveSpecimenReservation {
            return AdaptiveSpecimenReservation(
                code: code,
                title: title,
                phone: phone,
                region: region,
                threshold: threshold,
                channel: channel,
                visible: visible,
                windowDays: windowDays,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a adaptive specimen reservation in status requested.
    static func newAdaptiveSpecimenReservation(_ code: String, title: String) -> AdaptiveSpecimenReservation {
        return AdaptiveSpecimenReservation(
            code: code,
            title: title,
            phone: "",
            region: "",
            threshold: 0.0,
            channel: "",
            visible: false,
            windowDays: 0,
            version: 0,
            status: AdaptiveSpecimenReservationStatus.requested
        )
    }
}
