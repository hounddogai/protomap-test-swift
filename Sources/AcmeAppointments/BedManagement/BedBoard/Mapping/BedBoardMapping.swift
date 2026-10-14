import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board mapping is in its life cycle.
    enum BedBoardMappingStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A bed board mapping. Its code is unique within a tenant.
    final class BedBoardMapping {
        var code: String
        var label: String
        var allergy: String
        var archived: Bool
        var dosageMg: Double
        var clinicianID: String
        var visible: Bool
        var graceDays: Int
        var status: BedBoardMappingStatus

        init(code: String, label: String, allergy: String, archived: Bool, dosageMg: Double, clinicianID: String, visible: Bool, graceDays: Int, status: BedBoardMappingStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.archived = archived
            self.dosageMg = dosageMg
            self.clinicianID = clinicianID
            self.visible = visible
            self.graceDays = graceDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BedBoardMappingStatus) -> Bool {
            switch status {
            case .planned:
                return next == BedBoardMappingStatus.cancelled
            case .scheduled:
                return next == BedBoardMappingStatus.inProgress || next == BedBoardMappingStatus.completed
            case .inProgress:
                return next == BedBoardMappingStatus.completed || next == BedBoardMappingStatus.cancelled
            case .completed:
                return next == BedBoardMappingStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BedBoardMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedTotal() -> Double {
            return ((dosageMg + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardMapping {
            return BedBoardMapping(
                code: code,
                label: label,
                allergy: allergy,
                archived: archived,
                dosageMg: dosageMg,
                clinicianID: clinicianID,
                visible: visible,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a bed board mapping in status planned.
    static func newBedBoardMapping(_ code: String, label: String) -> BedBoardMapping {
        return BedBoardMapping(
            code: code,
            label: label,
            allergy: "",
            archived: false,
            dosageMg: 0.0,
            clinicianID: "",
            visible: false,
            graceDays: 0,
            status: BedBoardMappingStatus.planned
        )
    }
}
