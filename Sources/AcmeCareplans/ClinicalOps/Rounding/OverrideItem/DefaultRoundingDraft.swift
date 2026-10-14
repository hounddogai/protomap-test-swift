import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a default rounding draft is in its life cycle.
    enum DefaultRoundingDraftStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a default rounding draft and its current status.
    final class DefaultRoundingDraft {
        var code: String
        var label: String
        var revision: Int
        var description: String
        var clinicianID: String
        var encounterID: String
        var active: Bool
        var status: DefaultRoundingDraftStatus

        init(code: String, label: String, revision: Int, description: String, clinicianID: String, encounterID: String, active: Bool, status: DefaultRoundingDraftStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.description = description
            self.clinicianID = clinicianID
            self.encounterID = encounterID
            self.active = active
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultRoundingDraftStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == DefaultRoundingDraftStatus.reopened
            case .resolved:
                return next == DefaultRoundingDraftStatus.reopened || next == DefaultRoundingDraftStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: DefaultRoundingDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default rounding draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return Double(revision)
        }

        func copyValue() -> DefaultRoundingDraft {
            return DefaultRoundingDraft(
                code: code,
                label: label,
                revision: revision,
                description: description,
                clinicianID: clinicianID,
                encounterID: encounterID,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a default rounding draft in status open.
    static func newDefaultRoundingDraft(_ code: String, label: String) -> DefaultRoundingDraft {
        return DefaultRoundingDraft(
            code: code,
            label: label,
            revision: 0,
            description: "",
            clinicianID: "",
            encounterID: "",
            active: false,
            status: DefaultRoundingDraftStatus.`open`
        )
    }
}
