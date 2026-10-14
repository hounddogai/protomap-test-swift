import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a primary recall reservation is in its life cycle.
    enum PrimaryRecallReservationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a primary recall reservation and its current status.
    final class PrimaryRecallReservation {
        var code: String
        var label: String
        var cost: Double
        var refills: Int
        var durationMinutes: Int
        var status: PrimaryRecallReservationStatus

        init(code: String, label: String, cost: Double, refills: Int, durationMinutes: Int, status: PrimaryRecallReservationStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.refills = refills
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: PrimaryRecallReservationStatus) -> Bool {
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
                return next == PrimaryRecallReservationStatus.revoked || next == PrimaryRecallReservationStatus.expired
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

        func moveTo(_ next: PrimaryRecallReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary recall reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedVolume() -> Double {
            return ((cost - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryRecallReservation {
            return PrimaryRecallReservation(
                code: code,
                label: label,
                cost: cost,
                refills: refills,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary recall reservation in status requested.
    static func newPrimaryRecallReservation(_ code: String, label: String) -> PrimaryRecallReservation {
        return PrimaryRecallReservation(
            code: code,
            label: label,
            cost: 0.0,
            refills: 0,
            durationMinutes: 0,
            status: PrimaryRecallReservationStatus.requested
        )
    }
}
