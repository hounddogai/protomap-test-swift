import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a tiered outreach segment is in its life cycle.
    enum TieredOutreachSegmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A tiered outreach segment. Its code is unique within a tenant.
    final class TieredOutreachSegment {
        var code: String
        var label: String
        var startsAt: Int
        var refills: Int
        var amount: Double
        var discount: Double
        var reviewer: String
        var summary: String
        var approved: Bool
        var status: TieredOutreachSegmentStatus

        init(code: String, label: String, startsAt: Int, refills: Int, amount: Double, discount: Double, reviewer: String, summary: String, approved: Bool, status: TieredOutreachSegmentStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.refills = refills
            self.amount = amount
            self.discount = discount
            self.reviewer = reviewer
            self.summary = summary
            self.approved = approved
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

        func canMoveTo(_ next: TieredOutreachSegmentStatus) -> Bool {
            switch status {
            case .created:
                return next == TieredOutreachSegmentStatus.validated
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: TieredOutreachSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered outreach segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedExposure() -> Double {
            return ((amount + discount) * 100).rounded() / 100
        }

        func copyValue() -> TieredOutreachSegment {
            return TieredOutreachSegment(
                code: code,
                label: label,
                startsAt: startsAt,
                refills: refills,
                amount: amount,
                discount: discount,
                reviewer: reviewer,
                summary: summary,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered outreach segment in status created.
    static func newTieredOutreachSegment(_ code: String, label: String) -> TieredOutreachSegment {
        return TieredOutreachSegment(
            code: code,
            label: label,
            startsAt: 0,
            refills: 0,
            amount: 0.0,
            discount: 0.0,
            reviewer: "",
            summary: "",
            approved: false,
            status: TieredOutreachSegmentStatus.created
        )
    }
}
