import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral metric is in its life cycle.
    enum ReferralMetricStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A referral metric as the referral team keeps it.
    final class ReferralMetric {
        var code: String
        var label: String
        var specialty: String
        var startsAt: Int
        var diagnosisCode: String
        var status: ReferralMetricStatus

        init(code: String, label: String, specialty: String, startsAt: Int, diagnosisCode: String, status: ReferralMetricStatus) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.startsAt = startsAt
            self.diagnosisCode = diagnosisCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferralMetricStatus) -> Bool {
            switch status {
            case .draft:
                return next == ReferralMetricStatus.active
            case .pending:
                return next == ReferralMetricStatus.active || next == ReferralMetricStatus.suspended
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ReferralMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return Double(startsAt)
        }

        func copyValue() -> ReferralMetric {
            return ReferralMetric(
                code: code,
                label: label,
                specialty: specialty,
                startsAt: startsAt,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a referral metric in status draft.
    static func newReferralMetric(_ code: String, label: String) -> ReferralMetric {
        return ReferralMetric(
            code: code,
            label: label,
            specialty: "",
            startsAt: 0,
            diagnosisCode: "",
            status: ReferralMetricStatus.draft
        )
    }
}
