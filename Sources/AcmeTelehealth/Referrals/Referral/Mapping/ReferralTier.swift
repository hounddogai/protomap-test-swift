import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral tier is in its life cycle.
    enum ReferralTierStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A referral tier. Its code is unique within a tenant.
    final class ReferralTier {
        var code: String
        var name: String
        var limit: Int
        var visible: Bool
        var discount: Double
        var patientRef: String
        var summary: String
        var status: ReferralTierStatus

        init(code: String, name: String, limit: Int, visible: Bool, discount: Double, patientRef: String, summary: String, status: ReferralTierStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.visible = visible
            self.discount = discount
            self.patientRef = patientRef
            self.summary = summary
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferralTierStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ReferralTierStatus.stopped
            case .ready:
                return next == ReferralTierStatus.stopped
            case .draining:
                return next == ReferralTierStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferralTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedTotal() -> Double {
            return ((Double(limit) + discount) * 100).rounded() / 100
        }

        func copyValue() -> ReferralTier {
            return ReferralTier(
                code: code,
                name: name,
                limit: limit,
                visible: visible,
                discount: discount,
                patientRef: patientRef,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a referral tier in status idle.
    static func newReferralTier(_ code: String, name: String) -> ReferralTier {
        return ReferralTier(
            code: code,
            name: name,
            limit: 0,
            visible: false,
            discount: 0.0,
            patientRef: "",
            summary: "",
            status: ReferralTierStatus.idle
        )
    }
}
