import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach policy is in its life cycle.
    enum OutreachPolicyStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One outreach policy, with what the planners need to act on it.
    final class OutreachPolicy {
        var code: String
        var title: String
        var windowDays: Int
        var refills: Int
        var region: String
        var label: String
        var status: OutreachPolicyStatus

        init(code: String, title: String, windowDays: Int, refills: Int, region: String, label: String, status: OutreachPolicyStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.refills = refills
            self.region = region
            self.label = label
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

        func canMoveTo(_ next: OutreachPolicyStatus) -> Bool {
            switch status {
            case .created:
                return next == OutreachPolicyStatus.validated || next == OutreachPolicyStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == OutreachPolicyStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OutreachPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(title)"
        }

        func adjustedExposure() -> Double {
            return ((Double(refills) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> OutreachPolicy {
            return OutreachPolicy(
                code: code,
                title: title,
                windowDays: windowDays,
                refills: refills,
                region: region,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a outreach policy in status created.
    static func newOutreachPolicy(_ code: String, title: String) -> OutreachPolicy {
        return OutreachPolicy(
            code: code,
            title: title,
            windowDays: 0,
            refills: 0,
            region: "",
            label: "",
            status: OutreachPolicyStatus.created
        )
    }
}
