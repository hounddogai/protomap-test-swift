import AcmePlatform
import Foundation

extension Labs {
    /// Where a default accession window is in its life cycle.
    enum DefaultAccessionWindowStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a default accession window and its current status.
    final class DefaultAccessionWindow {
        var code: String
        var label: String
        var contactEmail: String
        var margin: Double
        var encounterID: String
        var payer: String
        var name: String
        var active: Bool
        var tags: [String]
        var ownerID: String
        var status: DefaultAccessionWindowStatus

        init(code: String, label: String, contactEmail: String, margin: Double, encounterID: String, payer: String, name: String, active: Bool, tags: [String], ownerID: String, status: DefaultAccessionWindowStatus) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.margin = margin
            self.encounterID = encounterID
            self.payer = payer
            self.name = name
            self.active = active
            self.tags = tags
            self.ownerID = ownerID
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

        func canMoveTo(_ next: DefaultAccessionWindowStatus) -> Bool {
            switch status {
            case .`open`:
                return next == DefaultAccessionWindowStatus.resolved || next == DefaultAccessionWindowStatus.archived
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == DefaultAccessionWindowStatus.reopened || next == DefaultAccessionWindowStatus.archived
            case .reopened:
                return next == DefaultAccessionWindowStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultAccessionWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default accession window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> DefaultAccessionWindow {
            return DefaultAccessionWindow(
                code: code,
                label: label,
                contactEmail: contactEmail,
                margin: margin,
                encounterID: encounterID,
                payer: payer,
                name: name,
                active: active,
                tags: tags,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a default accession window in status open.
    static func newDefaultAccessionWindow(_ code: String, label: String) -> DefaultAccessionWindow {
        return DefaultAccessionWindow(
            code: code,
            label: label,
            contactEmail: "",
            margin: 0.0,
            encounterID: "",
            payer: "",
            name: "",
            active: false,
            tags: [],
            ownerID: "",
            status: DefaultAccessionWindowStatus.`open`
        )
    }
}
