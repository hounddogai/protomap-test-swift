import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure reservation is in its life cycle.
    enum DisclosureReservationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A disclosure reservation as the disclosure team keeps it.
    final class DisclosureReservation {
        var code: String
        var title: String
        var updatedAt: Int
        var source: String
        var version: Int
        var status: DisclosureReservationStatus

        init(code: String, title: String, updatedAt: Int, source: String, version: Int, status: DisclosureReservationStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.source = source
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

        func canMoveTo(_ next: DisclosureReservationStatus) -> Bool {
            switch status {
            case .requested:
                return next == DisclosureReservationStatus.granted
            case .granted:
                return next == DisclosureReservationStatus.expired
            case .revoked:
                return next == DisclosureReservationStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DisclosureReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedValue() -> Double {
            return (Double(version) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureReservation {
            return DisclosureReservation(
                code: code,
                title: title,
                updatedAt: updatedAt,
                source: source,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a disclosure reservation in status requested.
    static func newDisclosureReservation(_ code: String, title: String) -> DisclosureReservation {
        return DisclosureReservation(
            code: code,
            title: title,
            updatedAt: 0,
            source: "",
            version: 0,
            status: DisclosureReservationStatus.requested
        )
    }
}
