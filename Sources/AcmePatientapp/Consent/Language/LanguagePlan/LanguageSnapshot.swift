import AcmePlatform
import Foundation

extension Consent {
    /// Where a language snapshot is in its life cycle.
    enum LanguageSnapshotStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A language snapshot as the language team keeps it.
    final class LanguageSnapshot {
        var code: String
        var label: String
        var encounterID: String
        var approved: Bool
        var category: String
        var title: String
        var attributes: [String: String]
        var notes: String
        var patientRef: String
        var segment: String
        var pinned: Bool
        var score: Double
        var status: LanguageSnapshotStatus

        init(code: String, label: String, encounterID: String, approved: Bool, category: String, title: String, attributes: [String: String], notes: String, patientRef: String, segment: String, pinned: Bool, score: Double, status: LanguageSnapshotStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.approved = approved
            self.category = category
            self.title = title
            self.attributes = attributes
            self.notes = notes
            self.patientRef = patientRef
            self.segment = segment
            self.pinned = pinned
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LanguageSnapshotStatus) -> Bool {
            switch status {
            case .planned:
                return next == LanguageSnapshotStatus.scheduled || next == LanguageSnapshotStatus.completed
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == LanguageSnapshotStatus.completed
            case .completed:
                return next == LanguageSnapshotStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LanguageSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> LanguageSnapshot {
            return LanguageSnapshot(
                code: code,
                label: label,
                encounterID: encounterID,
                approved: approved,
                category: category,
                title: title,
                attributes: attributes,
                notes: notes,
                patientRef: patientRef,
                segment: segment,
                pinned: pinned,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a language snapshot in status planned.
    static func newLanguageSnapshot(_ code: String, label: String) -> LanguageSnapshot {
        return LanguageSnapshot(
            code: code,
            label: label,
            encounterID: "",
            approved: false,
            category: "",
            title: "",
            attributes: [:],
            notes: "",
            patientRef: "",
            segment: "",
            pinned: false,
            score: 0.0,
            status: LanguageSnapshotStatus.planned
        )
    }
}
