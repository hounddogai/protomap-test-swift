import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a strict risk score request is in its life cycle.
    enum StrictRiskScoreRequestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a strict risk score request and its current status.
    final class StrictRiskScoreRequest {
        var code: String
        var name: String
        var notes: String
        var patientRef: String
        var ceiling: Double
        var status: StrictRiskScoreRequestStatus

        init(code: String, name: String, notes: String, patientRef: String, ceiling: Double, status: StrictRiskScoreRequestStatus) {
            self.code = code
            self.name = name
            self.notes = notes
            self.patientRef = patientRef
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

        func canMoveTo(_ next: StrictRiskScoreRequestStatus) -> Bool {
            switch status {
            case .new:
                return next == StrictRiskScoreRequestStatus.running || next == StrictRiskScoreRequestStatus.failed
            case .queued:
                return next == StrictRiskScoreRequestStatus.done || next == StrictRiskScoreRequestStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == StrictRiskScoreRequestStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictRiskScoreRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict risk score request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("strict risk score request") \(code)"
        }

        func measuredValue() -> Double {
            return ceiling
        }

        func copyValue() -> StrictRiskScoreRequest {
            return StrictRiskScoreRequest(
                code: code,
                name: name,
                notes: notes,
                patientRef: patientRef,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict risk score request in status new.
    static func newStrictRiskScoreRequest(_ code: String, name: String) -> StrictRiskScoreRequest {
        return StrictRiskScoreRequest(
            code: code,
            name: name,
            notes: "",
            patientRef: "",
            ceiling: 0.0,
            status: StrictRiskScoreRequestStatus.new
        )
    }
}
