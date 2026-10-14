import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy accession schedule is in its life cycle.
    enum LegacyAccessionScheduleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a legacy accession schedule and its current status.
    final class LegacyAccessionSchedule {
        var code: String
        var label: String
        var bed: String
        var version: Int
        var visible: Bool
        var refills: Int
        var allergy: String
        var ratio: Double
        var notes: String
        var pinned: Bool
        var attempts: Int
        var status: LegacyAccessionScheduleStatus

        init(code: String, label: String, bed: String, version: Int, visible: Bool, refills: Int, allergy: String, ratio: Double, notes: String, pinned: Bool, attempts: Int, status: LegacyAccessionScheduleStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.version = version
            self.visible = visible
            self.refills = refills
            self.allergy = allergy
            self.ratio = ratio
            self.notes = notes
            self.pinned = pinned
            self.attempts = attempts
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

        func canMoveTo(_ next: LegacyAccessionScheduleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == LegacyAccessionScheduleStatus.reopened
            case .reopened:
                return next == LegacyAccessionScheduleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyAccessionScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy accession schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedLoad() -> Double {
            return ((Double(attempts) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> LegacyAccessionSchedule {
            return LegacyAccessionSchedule(
                code: code,
                label: label,
                bed: bed,
                version: version,
                visible: visible,
                refills: refills,
                allergy: allergy,
                ratio: ratio,
                notes: notes,
                pinned: pinned,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy accession schedule in status open.
    static func newLegacyAccessionSchedule(_ code: String, label: String) -> LegacyAccessionSchedule {
        return LegacyAccessionSchedule(
            code: code,
            label: label,
            bed: "",
            version: 0,
            visible: false,
            refills: 0,
            allergy: "",
            ratio: 0.0,
            notes: "",
            pinned: false,
            attempts: 0,
            status: LegacyAccessionScheduleStatus.`open`
        )
    }
}
