import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a pending rounding tier is in its life cycle.
    enum PendingRoundingTierStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A pending rounding tier. Its code is unique within a tenant.
    final class PendingRoundingTier {
        var code: String
        var label: String
        var summary: String
        var threshold: Double
        var country: String
        var graceDays: Int
        var payer: String
        var retries: Int
        var status: PendingRoundingTierStatus

        init(code: String, label: String, summary: String, threshold: Double, country: String, graceDays: Int, payer: String, retries: Int, status: PendingRoundingTierStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.threshold = threshold
            self.country = country
            self.graceDays = graceDays
            self.payer = payer
            self.retries = retries
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

        func canMoveTo(_ next: PendingRoundingTierStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == PendingRoundingTierStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingRoundingTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending rounding tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("pending rounding tier") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(retries) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> PendingRoundingTier {
            return PendingRoundingTier(
                code: code,
                label: label,
                summary: summary,
                threshold: threshold,
                country: country,
                graceDays: graceDays,
                payer: payer,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a pending rounding tier in status open.
    static func newPendingRoundingTier(_ code: String, label: String) -> PendingRoundingTier {
        return PendingRoundingTier(
            code: code,
            label: label,
            summary: "",
            threshold: 0.0,
            country: "",
            graceDays: 0,
            payer: "",
            retries: 0,
            status: PendingRoundingTierStatus.`open`
        )
    }
}
