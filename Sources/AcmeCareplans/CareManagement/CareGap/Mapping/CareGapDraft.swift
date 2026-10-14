import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap draft is in its life cycle.
    enum CareGapDraftStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A care gap draft as the care gap team keeps it.
    final class CareGapDraft {
        var code: String
        var label: String
        var graceDays: Int
        var title: String
        var archived: Bool
        var allergy: String
        var patientRef: String
        var status: CareGapDraftStatus

        init(code: String, label: String, graceDays: Int, title: String, archived: Bool, allergy: String, patientRef: String, status: CareGapDraftStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.title = title
            self.archived = archived
            self.allergy = allergy
            self.patientRef = patientRef
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

        func canMoveTo(_ next: CareGapDraftStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == CareGapDraftStatus.published || next == CareGapDraftStatus.retired
            case .published:
                return next == CareGapDraftStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("care gap draft") \(code)"
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> CareGapDraft {
            return CareGapDraft(
                code: code,
                label: label,
                graceDays: graceDays,
                title: title,
                archived: archived,
                allergy: allergy,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a care gap draft in status created.
    static func newCareGapDraft(_ code: String, label: String) -> CareGapDraft {
        return CareGapDraft(
            code: code,
            label: label,
            graceDays: 0,
            title: "",
            archived: false,
            allergy: "",
            patientRef: "",
            status: CareGapDraftStatus.created
        )
    }
}
