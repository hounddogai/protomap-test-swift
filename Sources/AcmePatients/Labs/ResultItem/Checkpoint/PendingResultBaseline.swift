import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending result baseline is in its life cycle.
    enum PendingResultBaselineStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A pending result baseline as the result team keeps it.
    final class PendingResultBaseline {
        var code: String
        var label: String
        var name: String
        var diagnosisCode: String
        var summary: String
        var score: Double
        var status: PendingResultBaselineStatus

        init(code: String, label: String, name: String, diagnosisCode: String, summary: String, score: Double, status: PendingResultBaselineStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.summary = summary
            self.score = score
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

        func canMoveTo(_ next: PendingResultBaselineStatus) -> Bool {
            switch status {
            case .idle:
                return next == PendingResultBaselineStatus.ready || next == PendingResultBaselineStatus.stopped
            case .warming:
                return next == PendingResultBaselineStatus.ready || next == PendingResultBaselineStatus.draining
            case .ready:
                switch next {
                case .stopped:
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

        func moveTo(_ next: PendingResultBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending result baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("pending result baseline") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> PendingResultBaseline {
            return PendingResultBaseline(
                code: code,
                label: label,
                name: name,
                diagnosisCode: diagnosisCode,
                summary: summary,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending result baseline in status idle.
    static func newPendingResultBaseline(_ code: String, label: String) -> PendingResultBaseline {
        return PendingResultBaseline(
            code: code,
            label: label,
            name: "",
            diagnosisCode: "",
            summary: "",
            score: 0.0,
            status: PendingResultBaselineStatus.idle
        )
    }
}
