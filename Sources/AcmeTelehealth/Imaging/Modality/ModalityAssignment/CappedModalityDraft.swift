import AcmePlatform
import Foundation

extension Imaging {
    /// Where a capped modality draft is in its life cycle.
    enum CappedModalityDraftStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A capped modality draft. Its code is unique within a tenant.
    final class CappedModalityDraft {
        var code: String
        var label: String
        var maximum: Double
        var allergy: String
        var tags: [String]
        var facility: String
        var minimum: Double
        var patientRef: String
        var diagnosisCode: String
        var contactEmail: String
        var budget: Double
        var status: CappedModalityDraftStatus

        init(code: String, label: String, maximum: Double, allergy: String, tags: [String], facility: String, minimum: Double, patientRef: String, diagnosisCode: String, contactEmail: String, budget: Double, status: CappedModalityDraftStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.allergy = allergy
            self.tags = tags
            self.facility = facility
            self.minimum = minimum
            self.patientRef = patientRef
            self.diagnosisCode = diagnosisCode
            self.contactEmail = contactEmail
            self.budget = budget
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

        func canMoveTo(_ next: CappedModalityDraftStatus) -> Bool {
            switch status {
            case .new:
                return next == CappedModalityDraftStatus.queued
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

        func moveTo(_ next: CappedModalityDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped modality draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveTotal() -> Double {
            return ((minimum + maximum) * 100).rounded() / 100
        }

        func copyValue() -> CappedModalityDraft {
            return CappedModalityDraft(
                code: code,
                label: label,
                maximum: maximum,
                allergy: allergy,
                tags: tags,
                facility: facility,
                minimum: minimum,
                patientRef: patientRef,
                diagnosisCode: diagnosisCode,
                contactEmail: contactEmail,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a capped modality draft in status new.
    static func newCappedModalityDraft(_ code: String, label: String) -> CappedModalityDraft {
        return CappedModalityDraft(
            code: code,
            label: label,
            maximum: 0.0,
            allergy: "",
            tags: [],
            facility: "",
            minimum: 0.0,
            patientRef: "",
            diagnosisCode: "",
            contactEmail: "",
            budget: 0.0,
            status: CappedModalityDraftStatus.new
        )
    }
}
