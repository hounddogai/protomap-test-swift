import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral summary is in its life cycle.
    enum ReferralSummaryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A referral summary. Its code is unique within a tenant.
    final class ReferralSummary {
        var code: String
        var title: String
        var dosageMg: Double
        var archived: Bool
        var reviewer: String
        var phone: String
        var visible: Bool
        var label: String
        var country: String
        var unit: String
        var status: ReferralSummaryStatus

        init(code: String, title: String, dosageMg: Double, archived: Bool, reviewer: String, phone: String, visible: Bool, label: String, country: String, unit: String, status: ReferralSummaryStatus) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.archived = archived
            self.reviewer = reviewer
            self.phone = phone
            self.visible = visible
            self.label = label
            self.country = country
            self.unit = unit
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

        func canMoveTo(_ next: ReferralSummaryStatus) -> Bool {
            switch status {
            case .requested:
                return next == ReferralSummaryStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ReferralSummaryStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferralSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> ReferralSummary {
            return ReferralSummary(
                code: code,
                title: title,
                dosageMg: dosageMg,
                archived: archived,
                reviewer: reviewer,
                phone: phone,
                visible: visible,
                label: label,
                country: country,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a referral summary in status requested.
    static func newReferralSummary(_ code: String, title: String) -> ReferralSummary {
        return ReferralSummary(
            code: code,
            title: title,
            dosageMg: 0.0,
            archived: false,
            reviewer: "",
            phone: "",
            visible: false,
            label: "",
            country: "",
            unit: "",
            status: ReferralSummaryStatus.requested
        )
    }
}
