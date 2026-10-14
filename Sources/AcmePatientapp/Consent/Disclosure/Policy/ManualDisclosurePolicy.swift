import AcmePlatform
import Foundation

extension Consent {
    /// Where a manual disclosure policy is in its life cycle.
    enum ManualDisclosurePolicyStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One manual disclosure policy, with what the planners need to act on it.
    final class ManualDisclosurePolicy {
        var code: String
        var title: String
        var ceiling: Double
        var visible: Bool
        var description: String
        var segment: String
        var channel: String
        var revision: Int
        var approved: Bool
        var status: ManualDisclosurePolicyStatus

        init(code: String, title: String, ceiling: Double, visible: Bool, description: String, segment: String, channel: String, revision: Int, approved: Bool, status: ManualDisclosurePolicyStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.visible = visible
            self.description = description
            self.segment = segment
            self.channel = channel
            self.revision = revision
            self.approved = approved
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

        func canMoveTo(_ next: ManualDisclosurePolicyStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ManualDisclosurePolicyStatus.resolved
            case .resolved:
                return next == ManualDisclosurePolicyStatus.archived
            case .reopened:
                return next == ManualDisclosurePolicyStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualDisclosurePolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual disclosure policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveExposure() -> Double {
            return (Double(revision) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> ManualDisclosurePolicy {
            return ManualDisclosurePolicy(
                code: code,
                title: title,
                ceiling: ceiling,
                visible: visible,
                description: description,
                segment: segment,
                channel: channel,
                revision: revision,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a manual disclosure policy in status open.
    static func newManualDisclosurePolicy(_ code: String, title: String) -> ManualDisclosurePolicy {
        return ManualDisclosurePolicy(
            code: code,
            title: title,
            ceiling: 0.0,
            visible: false,
            description: "",
            segment: "",
            channel: "",
            revision: 0,
            approved: false,
            status: ManualDisclosurePolicyStatus.`open`
        )
    }
}
