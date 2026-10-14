import AcmePlatform
import Foundation

extension Referrals {
    /// Where a adaptive referral summary is in its life cycle.
    enum AdaptiveReferralSummaryStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A adaptive referral summary. Its code is unique within a tenant.
    final class AdaptiveReferralSummary {
        var code: String
        var title: String
        var visitMinutes: Int
        var ward: String
        var refills: Int
        var maximum: Double
        var region: String
        var approved: Bool
        var contactEmail: String
        var threshold: Double
        var floorValue: Double
        var status: AdaptiveReferralSummaryStatus

        init(code: String, title: String, visitMinutes: Int, ward: String, refills: Int, maximum: Double, region: String, approved: Bool, contactEmail: String, threshold: Double, floorValue: Double, status: AdaptiveReferralSummaryStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.ward = ward
            self.refills = refills
            self.maximum = maximum
            self.region = region
            self.approved = approved
            self.contactEmail = contactEmail
            self.threshold = threshold
            self.floorValue = floorValue
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

        func canMoveTo(_ next: AdaptiveReferralSummaryStatus) -> Bool {
            switch status {
            case .`open`:
                return next == AdaptiveReferralSummaryStatus.inReview || next == AdaptiveReferralSummaryStatus.archived
            case .inReview:
                return next == AdaptiveReferralSummaryStatus.resolved
            case .resolved:
                return next == AdaptiveReferralSummaryStatus.reopened
            case .reopened:
                return next == AdaptiveReferralSummaryStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveReferralSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive referral summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveVolume() -> Double {
            return ((Double(refills) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveReferralSummary {
            return AdaptiveReferralSummary(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                ward: ward,
                refills: refills,
                maximum: maximum,
                region: region,
                approved: approved,
                contactEmail: contactEmail,
                threshold: threshold,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a adaptive referral summary in status open.
    static func newAdaptiveReferralSummary(_ code: String, title: String) -> AdaptiveReferralSummary {
        return AdaptiveReferralSummary(
            code: code,
            title: title,
            visitMinutes: 0,
            ward: "",
            refills: 0,
            maximum: 0.0,
            region: "",
            approved: false,
            contactEmail: "",
            threshold: 0.0,
            floorValue: 0.0,
            status: AdaptiveReferralSummaryStatus.`open`
        )
    }
}
