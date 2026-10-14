import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession tier is in its life cycle.
    enum AccessionTierStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a accession tier and its current status.
    final class AccessionTier {
        var code: String
        var label: String
        var tags: [String]
        var encounterID: String
        var notes: String
        var source: String
        var bed: String
        var startsAt: Int
        var contactEmail: String
        var status: AccessionTierStatus

        init(code: String, label: String, tags: [String], encounterID: String, notes: String, source: String, bed: String, startsAt: Int, contactEmail: String, status: AccessionTierStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.encounterID = encounterID
            self.notes = notes
            self.source = source
            self.bed = bed
            self.startsAt = startsAt
            self.contactEmail = contactEmail
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AccessionTierStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AccessionTierStatus.rejected || next == AccessionTierStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == AccessionTierStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
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
            return Double(startsAt)
        }

        func copyValue() -> AccessionTier {
            return AccessionTier(
                code: code,
                label: label,
                tags: tags,
                encounterID: encounterID,
                notes: notes,
                source: source,
                bed: bed,
                startsAt: startsAt,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a accession tier in status proposed.
    static func newAccessionTier(_ code: String, label: String) -> AccessionTier {
        return AccessionTier(
            code: code,
            label: label,
            tags: [],
            encounterID: "",
            notes: "",
            source: "",
            bed: "",
            startsAt: 0,
            contactEmail: "",
            status: AccessionTierStatus.proposed
        )
    }
}
