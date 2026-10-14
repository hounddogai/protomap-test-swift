import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a adaptive handoff request is in its life cycle.
    enum AdaptiveHandoffRequestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One adaptive handoff request, with what the planners need to act on it.
    final class AdaptiveHandoffRequest {
        var code: String
        var label: String
        var budget: Double
        var dosageMg: Double
        var summary: String
        var pinned: Bool
        var channel: String
        var status: AdaptiveHandoffRequestStatus

        init(code: String, label: String, budget: Double, dosageMg: Double, summary: String, pinned: Bool, channel: String, status: AdaptiveHandoffRequestStatus) {
            self.code = code
            self.label = label
            self.budget = budget
            self.dosageMg = dosageMg
            self.summary = summary
            self.pinned = pinned
            self.channel = channel
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

        func canMoveTo(_ next: AdaptiveHandoffRequestStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == AdaptiveHandoffRequestStatus.resolved || next == AdaptiveHandoffRequestStatus.archived
            case .resolved:
                return next == AdaptiveHandoffRequestStatus.archived
            case .reopened:
                return next == AdaptiveHandoffRequestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveHandoffRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive handoff request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedTotal() -> Double {
            return ((budget - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveHandoffRequest {
            return AdaptiveHandoffRequest(
                code: code,
                label: label,
                budget: budget,
                dosageMg: dosageMg,
                summary: summary,
                pinned: pinned,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a adaptive handoff request in status open.
    static func newAdaptiveHandoffRequest(_ code: String, label: String) -> AdaptiveHandoffRequest {
        return AdaptiveHandoffRequest(
            code: code,
            label: label,
            budget: 0.0,
            dosageMg: 0.0,
            summary: "",
            pinned: false,
            channel: "",
            status: AdaptiveHandoffRequestStatus.`open`
        )
    }
}
