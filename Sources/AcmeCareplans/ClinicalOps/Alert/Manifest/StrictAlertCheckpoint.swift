import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a strict alert checkpoint is in its life cycle.
    enum StrictAlertCheckpointStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A strict alert checkpoint as the alert team keeps it.
    final class StrictAlertCheckpoint {
        var code: String
        var name: String
        var procedureCode: String
        var score: Double
        var ward: String
        var threshold: Double
        var region: String
        var status: StrictAlertCheckpointStatus

        init(code: String, name: String, procedureCode: String, score: Double, ward: String, threshold: Double, region: String, status: StrictAlertCheckpointStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.score = score
            self.ward = ward
            self.threshold = threshold
            self.region = region
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

        func canMoveTo(_ next: StrictAlertCheckpointStatus) -> Bool {
            switch status {
            case .new:
                return next == StrictAlertCheckpointStatus.running || next == StrictAlertCheckpointStatus.done
            case .queued:
                return next == StrictAlertCheckpointStatus.done || next == StrictAlertCheckpointStatus.failed
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

        func moveTo(_ next: StrictAlertCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict alert checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netValue() -> Double {
            return (threshold * score * 100).rounded() / 100
        }

        func copyValue() -> StrictAlertCheckpoint {
            return StrictAlertCheckpoint(
                code: code,
                name: name,
                procedureCode: procedureCode,
                score: score,
                ward: ward,
                threshold: threshold,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a strict alert checkpoint in status new.
    static func newStrictAlertCheckpoint(_ code: String, name: String) -> StrictAlertCheckpoint {
        return StrictAlertCheckpoint(
            code: code,
            name: name,
            procedureCode: "",
            score: 0.0,
            ward: "",
            threshold: 0.0,
            region: "",
            status: StrictAlertCheckpointStatus.new
        )
    }
}
