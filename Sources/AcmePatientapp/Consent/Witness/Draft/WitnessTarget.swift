import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness target is in its life cycle.
    enum WitnessTargetStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One witness target, with what the planners need to act on it.
    final class WitnessTarget {
        var code: String
        var name: String
        var limit: Int
        var sequence: Int
        var threshold: Double
        var batchSize: Int
        var approved: Bool
        var status: WitnessTargetStatus

        init(code: String, name: String, limit: Int, sequence: Int, threshold: Double, batchSize: Int, approved: Bool, status: WitnessTargetStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.sequence = sequence
            self.threshold = threshold
            self.batchSize = batchSize
            self.approved = approved
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

        func canMoveTo(_ next: WitnessTargetStatus) -> Bool {
            switch status {
            case .created:
                return next == WitnessTargetStatus.published || next == WitnessTargetStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == WitnessTargetStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WitnessTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("witness target") \(code)"
        }

        func weightedValue() -> Double {
            return (Double(limit) * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> WitnessTarget {
            return WitnessTarget(
                code: code,
                name: name,
                limit: limit,
                sequence: sequence,
                threshold: threshold,
                batchSize: batchSize,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a witness target in status created.
    static func newWitnessTarget(_ code: String, name: String) -> WitnessTarget {
        return WitnessTarget(
            code: code,
            name: name,
            limit: 0,
            sequence: 0,
            threshold: 0.0,
            batchSize: 0,
            approved: false,
            status: WitnessTargetStatus.created
        )
    }
}
