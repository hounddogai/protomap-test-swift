import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol claim is in its life cycle.
    enum CareProtocolClaimStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A care protocol claim as the care protocol team keeps it.
    final class CareProtocolClaim {
        var code: String
        var title: String
        var segment: String
        var country: String
        var priority: Int
        var reviewer: String
        var status: CareProtocolClaimStatus

        init(code: String, title: String, segment: String, country: String, priority: Int, reviewer: String, status: CareProtocolClaimStatus) {
            self.code = code
            self.title = title
            self.segment = segment
            self.country = country
            self.priority = priority
            self.reviewer = reviewer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolClaimStatus) -> Bool {
            switch status {
            case .`open`:
                return next == CareProtocolClaimStatus.resolved || next == CareProtocolClaimStatus.archived
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == CareProtocolClaimStatus.reopened
            case .reopened:
                return next == CareProtocolClaimStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("care protocol claim") \(code)"
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> CareProtocolClaim {
            return CareProtocolClaim(
                code: code,
                title: title,
                segment: segment,
                country: country,
                priority: priority,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a care protocol claim in status open.
    static func newCareProtocolClaim(_ code: String, title: String) -> CareProtocolClaim {
        return CareProtocolClaim(
            code: code,
            title: title,
            segment: "",
            country: "",
            priority: 0,
            reviewer: "",
            status: CareProtocolClaimStatus.`open`
        )
    }
}
