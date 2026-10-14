import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a legacy rounding reservation is in its life cycle.
    enum LegacyRoundingReservationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A legacy rounding reservation. Its code is unique within a tenant.
    final class LegacyRoundingReservation {
        var code: String
        var title: String
        var retries: Int
        var createdAt: Int
        var attempts: Int
        var dosageMg: Double
        var minimum: Double
        var label: String
        var status: LegacyRoundingReservationStatus

        init(code: String, title: String, retries: Int, createdAt: Int, attempts: Int, dosageMg: Double, minimum: Double, label: String, status: LegacyRoundingReservationStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.createdAt = createdAt
            self.attempts = attempts
            self.dosageMg = dosageMg
            self.minimum = minimum
            self.label = label
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

        func canMoveTo(_ next: LegacyRoundingReservationStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
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

        func moveTo(_ next: LegacyRoundingReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy rounding reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(title)"
        }

        func adjustedTotal() -> Double {
            return ((dosageMg - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyRoundingReservation {
            return LegacyRoundingReservation(
                code: code,
                title: title,
                retries: retries,
                createdAt: createdAt,
                attempts: attempts,
                dosageMg: dosageMg,
                minimum: minimum,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy rounding reservation in status requested.
    static func newLegacyRoundingReservation(_ code: String, title: String) -> LegacyRoundingReservation {
        return LegacyRoundingReservation(
            code: code,
            title: title,
            retries: 0,
            createdAt: 0,
            attempts: 0,
            dosageMg: 0.0,
            minimum: 0.0,
            label: "",
            status: LegacyRoundingReservationStatus.requested
        )
    }
}
