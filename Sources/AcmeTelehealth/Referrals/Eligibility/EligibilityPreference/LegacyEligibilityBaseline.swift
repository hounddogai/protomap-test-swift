import AcmePlatform
import Foundation

extension Referrals {
    /// Where a legacy eligibility baseline is in its life cycle.
    enum LegacyEligibilityBaselineStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A legacy eligibility baseline as the eligibility team keeps it.
    final class LegacyEligibilityBaseline {
        var code: String
        var name: String
        var payer: String
        var currency: String
        var ratio: Double
        var archived: Bool
        var patientRef: String
        var maximum: Double
        var ceiling: Double
        var startsAt: Int
        var status: LegacyEligibilityBaselineStatus

        init(code: String, name: String, payer: String, currency: String, ratio: Double, archived: Bool, patientRef: String, maximum: Double, ceiling: Double, startsAt: Int, status: LegacyEligibilityBaselineStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.currency = currency
            self.ratio = ratio
            self.archived = archived
            self.patientRef = patientRef
            self.maximum = maximum
            self.ceiling = ceiling
            self.startsAt = startsAt
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

        func canMoveTo(_ next: LegacyEligibilityBaselineStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LegacyEligibilityBaselineStatus.archived
            case .inReview:
                return next == LegacyEligibilityBaselineStatus.reopened || next == LegacyEligibilityBaselineStatus.archived
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == LegacyEligibilityBaselineStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyEligibilityBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy eligibility baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedVolume() -> Double {
            return (ceiling * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> LegacyEligibilityBaseline {
            return LegacyEligibilityBaseline(
                code: code,
                name: name,
                payer: payer,
                currency: currency,
                ratio: ratio,
                archived: archived,
                patientRef: patientRef,
                maximum: maximum,
                ceiling: ceiling,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a legacy eligibility baseline in status open.
    static func newLegacyEligibilityBaseline(_ code: String, name: String) -> LegacyEligibilityBaseline {
        return LegacyEligibilityBaseline(
            code: code,
            name: name,
            payer: "",
            currency: "",
            ratio: 0.0,
            archived: false,
            patientRef: "",
            maximum: 0.0,
            ceiling: 0.0,
            startsAt: 0,
            status: LegacyEligibilityBaselineStatus.`open`
        )
    }
}
