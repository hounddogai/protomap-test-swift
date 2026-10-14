import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a adaptive handoff variance is in its life cycle.
    enum AdaptiveHandoffVarianceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One adaptive handoff variance, with what the planners need to act on it.
    final class AdaptiveHandoffVariance {
        var code: String
        var label: String
        var timezone: String
        var ownerID: String
        var visible: Bool
        var startsAt: Int
        var status: AdaptiveHandoffVarianceStatus

        init(code: String, label: String, timezone: String, ownerID: String, visible: Bool, startsAt: Int, status: AdaptiveHandoffVarianceStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.ownerID = ownerID
            self.visible = visible
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveHandoffVarianceStatus) -> Bool {
            switch status {
            case .new:
                return next == AdaptiveHandoffVarianceStatus.running || next == AdaptiveHandoffVarianceStatus.failed
            case .queued:
                return next == AdaptiveHandoffVarianceStatus.running || next == AdaptiveHandoffVarianceStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == AdaptiveHandoffVarianceStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveHandoffVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive handoff variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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

        func copyValue() -> AdaptiveHandoffVariance {
            return AdaptiveHandoffVariance(
                code: code,
                label: label,
                timezone: timezone,
                ownerID: ownerID,
                visible: visible,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive handoff variance in status new.
    static func newAdaptiveHandoffVariance(_ code: String, label: String) -> AdaptiveHandoffVariance {
        return AdaptiveHandoffVariance(
            code: code,
            label: label,
            timezone: "",
            ownerID: "",
            visible: false,
            startsAt: 0,
            status: AdaptiveHandoffVarianceStatus.new
        )
    }
}
