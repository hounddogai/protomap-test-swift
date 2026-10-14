import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral slot is in its life cycle.
    enum ReferralSlotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A referral slot as the referral team keeps it.
    final class ReferralSlot {
        var code: String
        var title: String
        var segment: String
        var tags: [String]
        var summary: String
        var externalRef: String
        var score: Double
        var status: ReferralSlotStatus

        init(code: String, title: String, segment: String, tags: [String], summary: String, externalRef: String, score: Double, status: ReferralSlotStatus) {
            self.code = code
            self.title = title
            self.segment = segment
            self.tags = tags
            self.summary = summary
            self.externalRef = externalRef
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferralSlotStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: ReferralSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("referral slot") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> ReferralSlot {
            return ReferralSlot(
                code: code,
                title: title,
                segment: segment,
                tags: tags,
                summary: summary,
                externalRef: externalRef,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a referral slot in status proposed.
    static func newReferralSlot(_ code: String, title: String) -> ReferralSlot {
        return ReferralSlot(
            code: code,
            title: title,
            segment: "",
            tags: [],
            summary: "",
            externalRef: "",
            score: 0.0,
            status: ReferralSlotStatus.proposed
        )
    }
}
