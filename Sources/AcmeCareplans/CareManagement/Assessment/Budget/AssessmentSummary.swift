import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment summary is in its life cycle.
    enum AssessmentSummaryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A assessment summary. Its code is unique within a tenant.
    final class AssessmentSummary {
        var code: String
        var label: String
        var channel: String
        var refills: Int
        var phone: String
        var status: AssessmentSummaryStatus

        init(code: String, label: String, channel: String, refills: Int, phone: String, status: AssessmentSummaryStatus) {
            self.code = code
            self.label = label
            self.channel = channel
            self.refills = refills
            self.phone = phone
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

        func canMoveTo(_ next: AssessmentSummaryStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: AssessmentSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return Double(refills)
        }

        func copyValue() -> AssessmentSummary {
            return AssessmentSummary(
                code: code,
                label: label,
                channel: channel,
                refills: refills,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a assessment summary in status requested.
    static func newAssessmentSummary(_ code: String, label: String) -> AssessmentSummary {
        return AssessmentSummary(
            code: code,
            label: label,
            channel: "",
            refills: 0,
            phone: "",
            status: AssessmentSummaryStatus.requested
        )
    }
}
