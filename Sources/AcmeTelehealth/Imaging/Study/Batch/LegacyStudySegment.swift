import AcmePlatform
import Foundation

extension Imaging {
    /// Where a legacy study segment is in its life cycle.
    enum LegacyStudySegmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A legacy study segment as the study team keeps it.
    final class LegacyStudySegment {
        var code: String
        var label: String
        var allergy: String
        var graceDays: Int
        var encounterID: String
        var status: LegacyStudySegmentStatus

        init(code: String, label: String, allergy: String, graceDays: Int, encounterID: String, status: LegacyStudySegmentStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.graceDays = graceDays
            self.encounterID = encounterID
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

        func canMoveTo(_ next: LegacyStudySegmentStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == LegacyStudySegmentStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyStudySegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy study segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> LegacyStudySegment {
            return LegacyStudySegment(
                code: code,
                label: label,
                allergy: allergy,
                graceDays: graceDays,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy study segment in status open.
    static func newLegacyStudySegment(_ code: String, label: String) -> LegacyStudySegment {
        return LegacyStudySegment(
            code: code,
            label: label,
            allergy: "",
            graceDays: 0,
            encounterID: "",
            status: LegacyStudySegmentStatus.`open`
        )
    }
}
