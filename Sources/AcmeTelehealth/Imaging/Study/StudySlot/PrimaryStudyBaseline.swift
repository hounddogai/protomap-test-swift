import AcmePlatform
import Foundation

extension Imaging {
    /// Where a primary study baseline is in its life cycle.
    enum PrimaryStudyBaselineStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One primary study baseline, with what the planners need to act on it.
    final class PrimaryStudyBaseline {
        var code: String
        var label: String
        var maximum: Double
        var region: String
        var payer: String
        var ceiling: Double
        var status: PrimaryStudyBaselineStatus

        init(code: String, label: String, maximum: Double, region: String, payer: String, ceiling: Double, status: PrimaryStudyBaselineStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.region = region
            self.payer = payer
            self.ceiling = ceiling
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

        func canMoveTo(_ next: PrimaryStudyBaselineStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: PrimaryStudyBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary study baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveExposure() -> Double {
            return ((maximum - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryStudyBaseline {
            return PrimaryStudyBaseline(
                code: code,
                label: label,
                maximum: maximum,
                region: region,
                payer: payer,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a primary study baseline in status new.
    static func newPrimaryStudyBaseline(_ code: String, label: String) -> PrimaryStudyBaseline {
        return PrimaryStudyBaseline(
            code: code,
            label: label,
            maximum: 0.0,
            region: "",
            payer: "",
            ceiling: 0.0,
            status: PrimaryStudyBaselineStatus.new
        )
    }
}
