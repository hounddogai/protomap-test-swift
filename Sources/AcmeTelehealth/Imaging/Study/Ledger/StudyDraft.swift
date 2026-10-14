import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study draft is in its life cycle.
    enum StudyDraftStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One study draft, with what the planners need to act on it.
    final class StudyDraft {
        var code: String
        var name: String
        var maximum: Double
        var unit: String
        var ward: String
        var refills: Int
        var clinicianID: String
        var status: StudyDraftStatus

        init(code: String, name: String, maximum: Double, unit: String, ward: String, refills: Int, clinicianID: String, status: StudyDraftStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.unit = unit
            self.ward = ward
            self.refills = refills
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: StudyDraftStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
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

        func moveTo(_ next: StudyDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveValue() -> Double {
            return ((Double(refills) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> StudyDraft {
            return StudyDraft(
                code: code,
                name: name,
                maximum: maximum,
                unit: unit,
                ward: ward,
                refills: refills,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a study draft in status new.
    static func newStudyDraft(_ code: String, name: String) -> StudyDraft {
        return StudyDraft(
            code: code,
            name: name,
            maximum: 0.0,
            unit: "",
            ward: "",
            refills: 0,
            clinicianID: "",
            status: StudyDraftStatus.new
        )
    }
}
