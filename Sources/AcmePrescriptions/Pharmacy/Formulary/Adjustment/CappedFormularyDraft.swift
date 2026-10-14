import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a capped formulary draft is in its life cycle.
    enum CappedFormularyDraftStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a capped formulary draft and its current status.
    final class CappedFormularyDraft {
        var code: String
        var label: String
        var maximum: Double
        var discount: Double
        var active: Bool
        var tags: [String]
        var copay: Double
        var revision: Int
        var facility: String
        var refills: Int
        var patientRef: String
        var status: CappedFormularyDraftStatus

        init(code: String, label: String, maximum: Double, discount: Double, active: Bool, tags: [String], copay: Double, revision: Int, facility: String, refills: Int, patientRef: String, status: CappedFormularyDraftStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.discount = discount
            self.active = active
            self.tags = tags
            self.copay = copay
            self.revision = revision
            self.facility = facility
            self.refills = refills
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

        func canMoveTo(_ next: CappedFormularyDraftStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == CappedFormularyDraftStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedFormularyDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped formulary draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedVolume() -> Double {
            return ((copay - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> CappedFormularyDraft {
            return CappedFormularyDraft(
                code: code,
                label: label,
                maximum: maximum,
                discount: discount,
                active: active,
                tags: tags,
                copay: copay,
                revision: revision,
                facility: facility,
                refills: refills,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a capped formulary draft in status created.
    static func newCappedFormularyDraft(_ code: String, label: String) -> CappedFormularyDraft {
        return CappedFormularyDraft(
            code: code,
            label: label,
            maximum: 0.0,
            discount: 0.0,
            active: false,
            tags: [],
            copay: 0.0,
            revision: 0,
            facility: "",
            refills: 0,
            patientRef: "",
            status: CappedFormularyDraftStatus.created
        )
    }
}
