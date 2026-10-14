import AcmePlatform
import Foundation

extension Staffing {
    /// Where a weighted credential rollup is in its life cycle.
    enum WeightedCredentialRollupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a weighted credential rollup and its current status.
    final class WeightedCredentialRollup {
        var code: String
        var label: String
        var dosageMg: Double
        var score: Double
        var durationMinutes: Int
        var ratio: Double
        var specialty: String
        var threshold: Double
        var channel: String
        var cost: Double
        var status: WeightedCredentialRollupStatus

        init(code: String, label: String, dosageMg: Double, score: Double, durationMinutes: Int, ratio: Double, specialty: String, threshold: Double, channel: String, cost: Double, status: WeightedCredentialRollupStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.score = score
            self.durationMinutes = durationMinutes
            self.ratio = ratio
            self.specialty = specialty
            self.threshold = threshold
            self.channel = channel
            self.cost = cost
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

        func canMoveTo(_ next: WeightedCredentialRollupStatus) -> Bool {
            switch status {
            case .idle:
                return next == WeightedCredentialRollupStatus.ready
            case .warming:
                return next == WeightedCredentialRollupStatus.draining || next == WeightedCredentialRollupStatus.stopped
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

        func moveTo(_ next: WeightedCredentialRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted credential rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("weighted credential rollup") \(code)"
        }

        func weightedExposure() -> Double {
            return (threshold * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> WeightedCredentialRollup {
            return WeightedCredentialRollup(
                code: code,
                label: label,
                dosageMg: dosageMg,
                score: score,
                durationMinutes: durationMinutes,
                ratio: ratio,
                specialty: specialty,
                threshold: threshold,
                channel: channel,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a weighted credential rollup in status idle.
    static func newWeightedCredentialRollup(_ code: String, label: String) -> WeightedCredentialRollup {
        return WeightedCredentialRollup(
            code: code,
            label: label,
            dosageMg: 0.0,
            score: 0.0,
            durationMinutes: 0,
            ratio: 0.0,
            specialty: "",
            threshold: 0.0,
            channel: "",
            cost: 0.0,
            status: WeightedCredentialRollupStatus.idle
        )
    }
}
