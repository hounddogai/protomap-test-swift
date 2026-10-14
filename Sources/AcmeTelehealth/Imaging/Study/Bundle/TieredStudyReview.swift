import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered study review is in its life cycle.
    enum TieredStudyReviewStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A tiered study review as the study team keeps it.
    final class TieredStudyReview {
        var code: String
        var name: String
        var refills: Int
        var budget: Double
        var threshold: Double
        var currency: String
        var unit: String
        var externalRef: String
        var status: TieredStudyReviewStatus

        init(code: String, name: String, refills: Int, budget: Double, threshold: Double, currency: String, unit: String, externalRef: String, status: TieredStudyReviewStatus) {
            self.code = code
            self.name = name
            self.refills = refills
            self.budget = budget
            self.threshold = threshold
            self.currency = currency
            self.unit = unit
            self.externalRef = externalRef
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

        func canMoveTo(_ next: TieredStudyReviewStatus) -> Bool {
            switch status {
            case .requested:
                return next == TieredStudyReviewStatus.granted || next == TieredStudyReviewStatus.revoked
            case .granted:
                return next == TieredStudyReviewStatus.expired
            case .revoked:
                return next == TieredStudyReviewStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredStudyReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered study review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netValue() -> Double {
            return (threshold * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> TieredStudyReview {
            return TieredStudyReview(
                code: code,
                name: name,
                refills: refills,
                budget: budget,
                threshold: threshold,
                currency: currency,
                unit: unit,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a tiered study review in status requested.
    static func newTieredStudyReview(_ code: String, name: String) -> TieredStudyReview {
        return TieredStudyReview(
            code: code,
            name: name,
            refills: 0,
            budget: 0.0,
            threshold: 0.0,
            currency: "",
            unit: "",
            externalRef: "",
            status: TieredStudyReviewStatus.requested
        )
    }
}
