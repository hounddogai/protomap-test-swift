import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a strict bed board cycle is in its life cycle.
    enum StrictBedBoardCycleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One strict bed board cycle, with what the planners need to act on it.
    final class StrictBedBoardCycle {
        var code: String
        var name: String
        var updatedAt: Int
        var durationMinutes: Int
        var pinned: Bool
        var maximum: Double
        var patientRef: String
        var procedureCode: String
        var payer: String
        var diagnosisCode: String
        var ceiling: Double
        var status: StrictBedBoardCycleStatus

        init(code: String, name: String, updatedAt: Int, durationMinutes: Int, pinned: Bool, maximum: Double, patientRef: String, procedureCode: String, payer: String, diagnosisCode: String, ceiling: Double, status: StrictBedBoardCycleStatus) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.durationMinutes = durationMinutes
            self.pinned = pinned
            self.maximum = maximum
            self.patientRef = patientRef
            self.procedureCode = procedureCode
            self.payer = payer
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: StrictBedBoardCycleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
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
                return next == StrictBedBoardCycleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictBedBoardCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict bed board cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedLoad() -> Double {
            return ((maximum - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> StrictBedBoardCycle {
            return StrictBedBoardCycle(
                code: code,
                name: name,
                updatedAt: updatedAt,
                durationMinutes: durationMinutes,
                pinned: pinned,
                maximum: maximum,
                patientRef: patientRef,
                procedureCode: procedureCode,
                payer: payer,
                diagnosisCode: diagnosisCode,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict bed board cycle in status new.
    static func newStrictBedBoardCycle(_ code: String, name: String) -> StrictBedBoardCycle {
        return StrictBedBoardCycle(
            code: code,
            name: name,
            updatedAt: 0,
            durationMinutes: 0,
            pinned: false,
            maximum: 0.0,
            patientRef: "",
            procedureCode: "",
            payer: "",
            diagnosisCode: "",
            ceiling: 0.0,
            status: StrictBedBoardCycleStatus.new
        )
    }
}
