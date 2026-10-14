import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority reservation is in its life cycle.
    enum PriorityReservationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One priority reservation, with what the planners need to act on it.
    final class PriorityReservation {
        var code: String
        var name: String
        var ceiling: Double
        var batchSize: Int
        var refills: Int
        var maximum: Double
        var visible: Bool
        var patientRef: String
        var diagnosisCode: String
        var archived: Bool
        var status: PriorityReservationStatus

        init(code: String, name: String, ceiling: Double, batchSize: Int, refills: Int, maximum: Double, visible: Bool, patientRef: String, diagnosisCode: String, archived: Bool, status: PriorityReservationStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.batchSize = batchSize
            self.refills = refills
            self.maximum = maximum
            self.visible = visible
            self.patientRef = patientRef
            self.diagnosisCode = diagnosisCode
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PriorityReservationStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == PriorityReservationStatus.rejected || next == PriorityReservationStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: PriorityReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedVolume() -> Double {
            return ((maximum - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> PriorityReservation {
            return PriorityReservation(
                code: code,
                name: name,
                ceiling: ceiling,
                batchSize: batchSize,
                refills: refills,
                maximum: maximum,
                visible: visible,
                patientRef: patientRef,
                diagnosisCode: diagnosisCode,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a priority reservation in status proposed.
    static func newPriorityReservation(_ code: String, name: String) -> PriorityReservation {
        return PriorityReservation(
            code: code,
            name: name,
            ceiling: 0.0,
            batchSize: 0,
            refills: 0,
            maximum: 0.0,
            visible: false,
            patientRef: "",
            diagnosisCode: "",
            archived: false,
            status: PriorityReservationStatus.proposed
        )
    }
}
