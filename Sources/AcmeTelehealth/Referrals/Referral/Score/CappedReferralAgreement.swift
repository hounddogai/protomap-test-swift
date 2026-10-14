import AcmePlatform
import Foundation

extension Referrals {
    /// Where a capped referral agreement is in its life cycle.
    enum CappedReferralAgreementStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One capped referral agreement, with what the planners need to act on it.
    final class CappedReferralAgreement {
        var code: String
        var label: String
        var weight: Double
        var windowDays: Int
        var attempts: Int
        var visitMinutes: Int
        var unit: String
        var bed: String
        var capacity: Int
        var score: Double
        var rate: Double
        var status: CappedReferralAgreementStatus

        init(code: String, label: String, weight: Double, windowDays: Int, attempts: Int, visitMinutes: Int, unit: String, bed: String, capacity: Int, score: Double, rate: Double, status: CappedReferralAgreementStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.windowDays = windowDays
            self.attempts = attempts
            self.visitMinutes = visitMinutes
            self.unit = unit
            self.bed = bed
            self.capacity = capacity
            self.score = score
            self.rate = rate
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

        func canMoveTo(_ next: CappedReferralAgreementStatus) -> Bool {
            switch status {
            case .requested:
                return next == CappedReferralAgreementStatus.granted || next == CappedReferralAgreementStatus.expired
            case .granted:
                return next == CappedReferralAgreementStatus.revoked
            case .revoked:
                return next == CappedReferralAgreementStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedReferralAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped referral agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("capped referral agreement") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((Double(capacity) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> CappedReferralAgreement {
            return CappedReferralAgreement(
                code: code,
                label: label,
                weight: weight,
                windowDays: windowDays,
                attempts: attempts,
                visitMinutes: visitMinutes,
                unit: unit,
                bed: bed,
                capacity: capacity,
                score: score,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a capped referral agreement in status requested.
    static func newCappedReferralAgreement(_ code: String, label: String) -> CappedReferralAgreement {
        return CappedReferralAgreement(
            code: code,
            label: label,
            weight: 0.0,
            windowDays: 0,
            attempts: 0,
            visitMinutes: 0,
            unit: "",
            bed: "",
            capacity: 0,
            score: 0.0,
            rate: 0.0,
            status: CappedReferralAgreementStatus.requested
        )
    }
}
