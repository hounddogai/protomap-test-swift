import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range draft is in its life cycle.
    enum ReferenceRangeDraftStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a reference range draft and its current status.
    final class ReferenceRangeDraft {
        var code: String
        var title: String
        var allergy: String
        var checksum: String
        var externalRef: String
        var archived: Bool
        var diagnosisCode: String
        var score: Double
        var status: ReferenceRangeDraftStatus

        init(code: String, title: String, allergy: String, checksum: String, externalRef: String, archived: Bool, diagnosisCode: String, score: Double, status: ReferenceRangeDraftStatus) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.checksum = checksum
            self.externalRef = externalRef
            self.archived = archived
            self.diagnosisCode = diagnosisCode
            self.score = score
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

        func canMoveTo(_ next: ReferenceRangeDraftStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ReferenceRangeDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> ReferenceRangeDraft {
            return ReferenceRangeDraft(
                code: code,
                title: title,
                allergy: allergy,
                checksum: checksum,
                externalRef: externalRef,
                archived: archived,
                diagnosisCode: diagnosisCode,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a reference range draft in status draft.
    static func newReferenceRangeDraft(_ code: String, title: String) -> ReferenceRangeDraft {
        return ReferenceRangeDraft(
            code: code,
            title: title,
            allergy: "",
            checksum: "",
            externalRef: "",
            archived: false,
            diagnosisCode: "",
            score: 0.0,
            status: ReferenceRangeDraftStatus.draft
        )
    }
}
