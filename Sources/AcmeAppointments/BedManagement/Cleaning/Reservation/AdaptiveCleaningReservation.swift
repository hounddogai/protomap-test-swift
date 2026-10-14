import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive cleaning reservation is in its life cycle.
    enum AdaptiveCleaningReservationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A adaptive cleaning reservation as the cleaning team keeps it.
    final class AdaptiveCleaningReservation {
        var code: String
        var name: String
        var rate: Double
        var batchSize: Int
        var updatedAt: Int
        var channel: String
        var segment: String
        var title: String
        var active: Bool
        var status: AdaptiveCleaningReservationStatus

        init(code: String, name: String, rate: Double, batchSize: Int, updatedAt: Int, channel: String, segment: String, title: String, active: Bool, status: AdaptiveCleaningReservationStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.batchSize = batchSize
            self.updatedAt = updatedAt
            self.channel = channel
            self.segment = segment
            self.title = title
            self.active = active
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

        func canMoveTo(_ next: AdaptiveCleaningReservationStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == AdaptiveCleaningReservationStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveCleaningReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive cleaning reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedVolume() -> Double {
            return ((rate - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveCleaningReservation {
            return AdaptiveCleaningReservation(
                code: code,
                name: name,
                rate: rate,
                batchSize: batchSize,
                updatedAt: updatedAt,
                channel: channel,
                segment: segment,
                title: title,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a adaptive cleaning reservation in status requested.
    static func newAdaptiveCleaningReservation(_ code: String, name: String) -> AdaptiveCleaningReservation {
        return AdaptiveCleaningReservation(
            code: code,
            name: name,
            rate: 0.0,
            batchSize: 0,
            updatedAt: 0,
            channel: "",
            segment: "",
            title: "",
            active: false,
            status: AdaptiveCleaningReservationStatus.requested
        )
    }
}
