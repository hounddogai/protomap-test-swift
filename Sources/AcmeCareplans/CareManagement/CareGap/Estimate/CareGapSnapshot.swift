import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap snapshot is in its life cycle.
    enum CareGapSnapshotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One care gap snapshot, with what the planners need to act on it.
    final class CareGapSnapshot {
        var code: String
        var name: String
        var procedureCode: String
        var segment: String
        var encounterID: String
        var clinicianID: String
        var quantity: Int
        var status: CareGapSnapshotStatus

        init(code: String, name: String, procedureCode: String, segment: String, encounterID: String, clinicianID: String, quantity: Int, status: CareGapSnapshotStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.segment = segment
            self.encounterID = encounterID
            self.clinicianID = clinicianID
            self.quantity = quantity
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

        func canMoveTo(_ next: CareGapSnapshotStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == CareGapSnapshotStatus.failed
            case .running:
                return next == CareGapSnapshotStatus.done || next == CareGapSnapshotStatus.failed
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

        func moveTo(_ next: CareGapSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> CareGapSnapshot {
            return CareGapSnapshot(
                code: code,
                name: name,
                procedureCode: procedureCode,
                segment: segment,
                encounterID: encounterID,
                clinicianID: clinicianID,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a care gap snapshot in status new.
    static func newCareGapSnapshot(_ code: String, name: String) -> CareGapSnapshot {
        return CareGapSnapshot(
            code: code,
            name: name,
            procedureCode: "",
            segment: "",
            encounterID: "",
            clinicianID: "",
            quantity: 0,
            status: CareGapSnapshotStatus.new
        )
    }
}
