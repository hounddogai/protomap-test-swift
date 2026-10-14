import AcmePlatform
import Foundation

extension Referrals {
    /// Where a fallback referral reservation is in its life cycle.
    enum FallbackReferralReservationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A fallback referral reservation as the referral team keeps it.
    final class FallbackReferralReservation {
        var code: String
        var label: String
        var refills: Int
        var facility: String
        var limit: Int
        var createdAt: Int
        var discount: Double
        var active: Bool
        var status: FallbackReferralReservationStatus

        init(code: String, label: String, refills: Int, facility: String, limit: Int, createdAt: Int, discount: Double, active: Bool, status: FallbackReferralReservationStatus) {
            self.code = code
            self.label = label
            self.refills = refills
            self.facility = facility
            self.limit = limit
            self.createdAt = createdAt
            self.discount = discount
            self.active = active
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackReferralReservationStatus) -> Bool {
            switch status {
            case .draft:
                return next == FallbackReferralReservationStatus.pending || next == FallbackReferralReservationStatus.suspended
            case .pending:
                return next == FallbackReferralReservationStatus.active || next == FallbackReferralReservationStatus.suspended
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == FallbackReferralReservationStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackReferralReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback referral reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedValue() -> Double {
            return (Double(createdAt) * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> FallbackReferralReservation {
            return FallbackReferralReservation(
                code: code,
                label: label,
                refills: refills,
                facility: facility,
                limit: limit,
                createdAt: createdAt,
                discount: discount,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a fallback referral reservation in status draft.
    static func newFallbackReferralReservation(_ code: String, label: String) -> FallbackReferralReservation {
        return FallbackReferralReservation(
            code: code,
            label: label,
            refills: 0,
            facility: "",
            limit: 0,
            createdAt: 0,
            discount: 0.0,
            active: false,
            status: FallbackReferralReservationStatus.draft
        )
    }
}
