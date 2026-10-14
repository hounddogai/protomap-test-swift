import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a default remittance reservation is in its life cycle.
    enum DefaultRemittanceReservationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One default remittance reservation, with what the planners need to act on it.
    final class DefaultRemittanceReservation {
        var code: String
        var title: String
        var pinned: Bool
        var diagnosisCode: String
        var clinicianID: String
        var dosageMg: Double
        var reviewer: String
        var expiresAt: Int
        var status: DefaultRemittanceReservationStatus

        init(code: String, title: String, pinned: Bool, diagnosisCode: String, clinicianID: String, dosageMg: Double, reviewer: String, expiresAt: Int, status: DefaultRemittanceReservationStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.diagnosisCode = diagnosisCode
            self.clinicianID = clinicianID
            self.dosageMg = dosageMg
            self.reviewer = reviewer
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: DefaultRemittanceReservationStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == DefaultRemittanceReservationStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultRemittanceReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default remittance reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("default remittance reservation") \(code)"
        }

        func projectedExposure() -> Double {
            return (dosageMg * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> DefaultRemittanceReservation {
            return DefaultRemittanceReservation(
                code: code,
                title: title,
                pinned: pinned,
                diagnosisCode: diagnosisCode,
                clinicianID: clinicianID,
                dosageMg: dosageMg,
                reviewer: reviewer,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default remittance reservation in status requested.
    static func newDefaultRemittanceReservation(_ code: String, title: String) -> DefaultRemittanceReservation {
        return DefaultRemittanceReservation(
            code: code,
            title: title,
            pinned: false,
            diagnosisCode: "",
            clinicianID: "",
            dosageMg: 0.0,
            reviewer: "",
            expiresAt: 0,
            status: DefaultRemittanceReservationStatus.requested
        )
    }
}
