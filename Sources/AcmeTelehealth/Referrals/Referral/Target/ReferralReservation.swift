import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral reservation is in its life cycle.
    enum ReferralReservationStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a referral reservation and its current status.
    final class ReferralReservation {
        var code: String
        var label: String
        var visible: Bool
        var source: String
        var maximum: Double
        var acuity: Int
        var status: ReferralReservationStatus

        init(code: String, label: String, visible: Bool, source: String, maximum: Double, acuity: Int, status: ReferralReservationStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.source = source
            self.maximum = maximum
            self.acuity = acuity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferralReservationStatus) -> Bool {
            switch status {
            case .created:
                return next == ReferralReservationStatus.validated
            case .validated:
                return next == ReferralReservationStatus.published || next == ReferralReservationStatus.retired
            case .published:
                return next == ReferralReservationStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferralReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netExposure() -> Double {
            return ((Double(acuity) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> ReferralReservation {
            return ReferralReservation(
                code: code,
                label: label,
                visible: visible,
                source: source,
                maximum: maximum,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a referral reservation in status created.
    static func newReferralReservation(_ code: String, label: String) -> ReferralReservation {
        return ReferralReservation(
            code: code,
            label: label,
            visible: false,
            source: "",
            maximum: 0.0,
            acuity: 0,
            status: ReferralReservationStatus.created
        )
    }
}
