import AcmePlatform
import Foundation

extension Imaging {
    /// Where a adaptive priority claim is in its life cycle.
    enum AdaptivePriorityClaimStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One adaptive priority claim, with what the planners need to act on it.
    final class AdaptivePriorityClaim {
        var code: String
        var label: String
        var diagnosisCode: String
        var updatedAt: Int
        var threshold: Double
        var title: String
        var status: AdaptivePriorityClaimStatus

        init(code: String, label: String, diagnosisCode: String, updatedAt: Int, threshold: Double, title: String, status: AdaptivePriorityClaimStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.updatedAt = updatedAt
            self.threshold = threshold
            self.title = title
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptivePriorityClaimStatus) -> Bool {
            switch status {
            case .idle:
                return next == AdaptivePriorityClaimStatus.stopped
            case .warming:
                return next == AdaptivePriorityClaimStatus.ready || next == AdaptivePriorityClaimStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: AdaptivePriorityClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive priority claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("adaptive priority claim") \(code)"
        }

        func netValue() -> Double {
            return (Double(updatedAt) * threshold * 100).rounded() / 100
        }

        func copyValue() -> AdaptivePriorityClaim {
            return AdaptivePriorityClaim(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                updatedAt: updatedAt,
                threshold: threshold,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive priority claim in status idle.
    static func newAdaptivePriorityClaim(_ code: String, label: String) -> AdaptivePriorityClaim {
        return AdaptivePriorityClaim(
            code: code,
            label: label,
            diagnosisCode: "",
            updatedAt: 0,
            threshold: 0.0,
            title: "",
            status: AdaptivePriorityClaimStatus.idle
        )
    }
}
