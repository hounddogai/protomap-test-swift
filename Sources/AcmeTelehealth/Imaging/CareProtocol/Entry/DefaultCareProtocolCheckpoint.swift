import AcmePlatform
import Foundation

extension Imaging {
    /// Where a default care protocol checkpoint is in its life cycle.
    enum DefaultCareProtocolCheckpointStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A default care protocol checkpoint as the care protocol team keeps it.
    final class DefaultCareProtocolCheckpoint {
        var code: String
        var label: String
        var diagnosisCode: String
        var tags: [String]
        var procedureCode: String
        var score: Double
        var status: DefaultCareProtocolCheckpointStatus

        init(code: String, label: String, diagnosisCode: String, tags: [String], procedureCode: String, score: Double, status: DefaultCareProtocolCheckpointStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.tags = tags
            self.procedureCode = procedureCode
            self.score = score
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

        func canMoveTo(_ next: DefaultCareProtocolCheckpointStatus) -> Bool {
            switch status {
            case .new:
                return next == DefaultCareProtocolCheckpointStatus.done
            case .queued:
                return next == DefaultCareProtocolCheckpointStatus.done || next == DefaultCareProtocolCheckpointStatus.failed
            case .running:
                return next == DefaultCareProtocolCheckpointStatus.done || next == DefaultCareProtocolCheckpointStatus.failed
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

        func moveTo(_ next: DefaultCareProtocolCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default care protocol checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("default care protocol checkpoint") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> DefaultCareProtocolCheckpoint {
            return DefaultCareProtocolCheckpoint(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                tags: tags,
                procedureCode: procedureCode,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a default care protocol checkpoint in status new.
    static func newDefaultCareProtocolCheckpoint(_ code: String, label: String) -> DefaultCareProtocolCheckpoint {
        return DefaultCareProtocolCheckpoint(
            code: code,
            label: label,
            diagnosisCode: "",
            tags: [],
            procedureCode: "",
            score: 0.0,
            status: DefaultCareProtocolCheckpointStatus.new
        )
    }
}
