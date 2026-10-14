import AcmePlatform
import Foundation

extension Imaging {
    /// Where a lenient worklist template is in its life cycle.
    enum LenientWorklistTemplateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a lenient worklist template and its current status.
    final class LenientWorklistTemplate {
        var code: String
        var label: String
        var allergy: String
        var summary: String
        var bed: String
        var archived: Bool
        var version: Int
        var status: LenientWorklistTemplateStatus

        init(code: String, label: String, allergy: String, summary: String, bed: String, archived: Bool, version: Int, status: LenientWorklistTemplateStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.summary = summary
            self.bed = bed
            self.archived = archived
            self.version = version
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientWorklistTemplateStatus) -> Bool {
            switch status {
            case .requested:
                return next == LenientWorklistTemplateStatus.granted || next == LenientWorklistTemplateStatus.expired
            case .granted:
                return next == LenientWorklistTemplateStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: LenientWorklistTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient worklist template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> LenientWorklistTemplate {
            return LenientWorklistTemplate(
                code: code,
                label: label,
                allergy: allergy,
                summary: summary,
                bed: bed,
                archived: archived,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient worklist template in status requested.
    static func newLenientWorklistTemplate(_ code: String, label: String) -> LenientWorklistTemplate {
        return LenientWorklistTemplate(
            code: code,
            label: label,
            allergy: "",
            summary: "",
            bed: "",
            archived: false,
            version: 0,
            status: LenientWorklistTemplateStatus.requested
        )
    }
}
