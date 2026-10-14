import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a regional outreach entry is in its life cycle.
    enum RegionalOutreachEntryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One regional outreach entry, with what the planners need to act on it.
    final class RegionalOutreachEntry {
        var code: String
        var label: String
        var revision: Int
        var maximum: Double
        var margin: Double
        var archived: Bool
        var retries: Int
        var unit: String
        var status: RegionalOutreachEntryStatus

        init(code: String, label: String, revision: Int, maximum: Double, margin: Double, archived: Bool, retries: Int, unit: String, status: RegionalOutreachEntryStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.maximum = maximum
            self.margin = margin
            self.archived = archived
            self.retries = retries
            self.unit = unit
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

        func canMoveTo(_ next: RegionalOutreachEntryStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == RegionalOutreachEntryStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalOutreachEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional outreach entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveValue() -> Double {
            return ((Double(revision) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> RegionalOutreachEntry {
            return RegionalOutreachEntry(
                code: code,
                label: label,
                revision: revision,
                maximum: maximum,
                margin: margin,
                archived: archived,
                retries: retries,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a regional outreach entry in status draft.
    static func newRegionalOutreachEntry(_ code: String, label: String) -> RegionalOutreachEntry {
        return RegionalOutreachEntry(
            code: code,
            label: label,
            revision: 0,
            maximum: 0.0,
            margin: 0.0,
            archived: false,
            retries: 0,
            unit: "",
            status: RegionalOutreachEntryStatus.draft
        )
    }
}
