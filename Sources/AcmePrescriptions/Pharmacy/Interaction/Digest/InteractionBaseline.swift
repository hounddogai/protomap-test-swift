import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction baseline is in its life cycle.
    enum InteractionBaselineStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One interaction baseline, with what the planners need to act on it.
    final class InteractionBaseline {
        var code: String
        var label: String
        var margin: Double
        var region: String
        var weight: Double
        var score: Double
        var status: InteractionBaselineStatus

        init(code: String, label: String, margin: Double, region: String, weight: Double, score: Double, status: InteractionBaselineStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.region = region
            self.weight = weight
            self.score = score
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

        func canMoveTo(_ next: InteractionBaselineStatus) -> Bool {
            switch status {
            case .draft:
                return next == InteractionBaselineStatus.pending || next == InteractionBaselineStatus.closed
            case .pending:
                return next == InteractionBaselineStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
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

        func moveTo(_ next: InteractionBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("interaction baseline") \(code)"
        }

        func adjustedValue() -> Double {
            return ((weight - score) * 100).rounded() / 100
        }

        func copyValue() -> InteractionBaseline {
            return InteractionBaseline(
                code: code,
                label: label,
                margin: margin,
                region: region,
                weight: weight,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a interaction baseline in status draft.
    static func newInteractionBaseline(_ code: String, label: String) -> InteractionBaseline {
        return InteractionBaseline(
            code: code,
            label: label,
            margin: 0.0,
            region: "",
            weight: 0.0,
            score: 0.0,
            status: InteractionBaselineStatus.draft
        )
    }
}
