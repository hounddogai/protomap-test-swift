import AcmePlatform
import Foundation

extension Referrals {
    /// Where a regional eligibility estimate is in its life cycle.
    enum RegionalEligibilityEstimateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a regional eligibility estimate and its current status.
    final class RegionalEligibilityEstimate {
        var code: String
        var title: String
        var checksum: String
        var visible: Bool
        var timezone: String
        var updatedAt: Int
        var ceiling: Double
        var tags: [String]
        var amount: Double
        var status: RegionalEligibilityEstimateStatus

        init(code: String, title: String, checksum: String, visible: Bool, timezone: String, updatedAt: Int, ceiling: Double, tags: [String], amount: Double, status: RegionalEligibilityEstimateStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.visible = visible
            self.timezone = timezone
            self.updatedAt = updatedAt
            self.ceiling = ceiling
            self.tags = tags
            self.amount = amount
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

        func canMoveTo(_ next: RegionalEligibilityEstimateStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == RegionalEligibilityEstimateStatus.reopened || next == RegionalEligibilityEstimateStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == RegionalEligibilityEstimateStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalEligibilityEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional eligibility estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("regional eligibility estimate") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedVolume() -> Double {
            return ((Double(updatedAt) - amount) * 100).rounded() / 100
        }

        func copyValue() -> RegionalEligibilityEstimate {
            return RegionalEligibilityEstimate(
                code: code,
                title: title,
                checksum: checksum,
                visible: visible,
                timezone: timezone,
                updatedAt: updatedAt,
                ceiling: ceiling,
                tags: tags,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional eligibility estimate in status open.
    static func newRegionalEligibilityEstimate(_ code: String, title: String) -> RegionalEligibilityEstimate {
        return RegionalEligibilityEstimate(
            code: code,
            title: title,
            checksum: "",
            visible: false,
            timezone: "",
            updatedAt: 0,
            ceiling: 0.0,
            tags: [],
            amount: 0.0,
            status: RegionalEligibilityEstimateStatus.`open`
        )
    }
}
