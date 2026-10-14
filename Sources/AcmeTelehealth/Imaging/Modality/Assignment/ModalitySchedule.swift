import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality schedule is in its life cycle.
    enum ModalityScheduleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a modality schedule and its current status.
    final class ModalitySchedule {
        var code: String
        var name: String
        var allergy: String
        var checksum: String
        var copay: Double
        var label: String
        var score: Double
        var sequence: Int
        var acuity: Int
        var ratio: Double
        var archived: Bool
        var status: ModalityScheduleStatus

        init(code: String, name: String, allergy: String, checksum: String, copay: Double, label: String, score: Double, sequence: Int, acuity: Int, ratio: Double, archived: Bool, status: ModalityScheduleStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.checksum = checksum
            self.copay = copay
            self.label = label
            self.score = score
            self.sequence = sequence
            self.acuity = acuity
            self.ratio = ratio
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ModalityScheduleStatus) -> Bool {
            switch status {
            case .draft:
                return next == ModalityScheduleStatus.pending || next == ModalityScheduleStatus.active
            case .pending:
                return next == ModalityScheduleStatus.closed
            case .active:
                return next == ModalityScheduleStatus.suspended || next == ModalityScheduleStatus.closed
            case .suspended:
                return next == ModalityScheduleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ModalityScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
        }

        func netVolume() -> Double {
            return ((Double(sequence) + score) * 100).rounded() / 100
        }

        func copyValue() -> ModalitySchedule {
            return ModalitySchedule(
                code: code,
                name: name,
                allergy: allergy,
                checksum: checksum,
                copay: copay,
                label: label,
                score: score,
                sequence: sequence,
                acuity: acuity,
                ratio: ratio,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a modality schedule in status draft.
    static func newModalitySchedule(_ code: String, name: String) -> ModalitySchedule {
        return ModalitySchedule(
            code: code,
            name: name,
            allergy: "",
            checksum: "",
            copay: 0.0,
            label: "",
            score: 0.0,
            sequence: 0,
            acuity: 0,
            ratio: 0.0,
            archived: false,
            status: ModalityScheduleStatus.draft
        )
    }
}
