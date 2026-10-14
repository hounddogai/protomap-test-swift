import AcmePlatform
import Foundation

extension Consent {
    /// Where a global disclosure snapshot is in its life cycle.
    enum GlobalDisclosureSnapshotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One global disclosure snapshot, with what the planners need to act on it.
    final class GlobalDisclosureSnapshot {
        var code: String
        var label: String
        var weight: Double
        var margin: Double
        var notes: String
        var minimum: Double
        var payer: String
        var updatedAt: Int
        var segment: String
        var encounterID: String
        var status: GlobalDisclosureSnapshotStatus

        init(code: String, label: String, weight: Double, margin: Double, notes: String, minimum: Double, payer: String, updatedAt: Int, segment: String, encounterID: String, status: GlobalDisclosureSnapshotStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.margin = margin
            self.notes = notes
            self.minimum = minimum
            self.payer = payer
            self.updatedAt = updatedAt
            self.segment = segment
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

        func canMoveTo(_ next: GlobalDisclosureSnapshotStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == GlobalDisclosureSnapshotStatus.reopened || next == GlobalDisclosureSnapshotStatus.archived
            case .reopened:
                return next == GlobalDisclosureSnapshotStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalDisclosureSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global disclosure snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("global disclosure snapshot") \(code)"
        }

        func netExposure() -> Double {
            return ((margin - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalDisclosureSnapshot {
            return GlobalDisclosureSnapshot(
                code: code,
                label: label,
                weight: weight,
                margin: margin,
                notes: notes,
                minimum: minimum,
                payer: payer,
                updatedAt: updatedAt,
                segment: segment,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a global disclosure snapshot in status open.
    static func newGlobalDisclosureSnapshot(_ code: String, label: String) -> GlobalDisclosureSnapshot {
        return GlobalDisclosureSnapshot(
            code: code,
            label: label,
            weight: 0.0,
            margin: 0.0,
            notes: "",
            minimum: 0.0,
            payer: "",
            updatedAt: 0,
            segment: "",
            encounterID: "",
            status: GlobalDisclosureSnapshotStatus.`open`
        )
    }
}
