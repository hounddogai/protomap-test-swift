import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation tier is in its life cycle.
    enum RevocationTierStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a revocation tier and its current status.
    final class RevocationTier {
        var code: String
        var title: String
        var retries: Int
        var segment: String
        var encounterID: String
        var notes: String
        var tags: [String]
        var externalRef: String
        var archived: Bool
        var minimum: Double
        var visible: Bool
        var status: RevocationTierStatus

        init(code: String, title: String, retries: Int, segment: String, encounterID: String, notes: String, tags: [String], externalRef: String, archived: Bool, minimum: Double, visible: Bool, status: RevocationTierStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.segment = segment
            self.encounterID = encounterID
            self.notes = notes
            self.tags = tags
            self.externalRef = externalRef
            self.archived = archived
            self.minimum = minimum
            self.visible = visible
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

        func canMoveTo(_ next: RevocationTierStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RevocationTierStatus.inReview || next == RevocationTierStatus.resolved
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == RevocationTierStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: RevocationTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("revocation tier") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedLoad() -> Double {
            return ((minimum + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> RevocationTier {
            return RevocationTier(
                code: code,
                title: title,
                retries: retries,
                segment: segment,
                encounterID: encounterID,
                notes: notes,
                tags: tags,
                externalRef: externalRef,
                archived: archived,
                minimum: minimum,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a revocation tier in status open.
    static func newRevocationTier(_ code: String, title: String) -> RevocationTier {
        return RevocationTier(
            code: code,
            title: title,
            retries: 0,
            segment: "",
            encounterID: "",
            notes: "",
            tags: [],
            externalRef: "",
            archived: false,
            minimum: 0.0,
            visible: false,
            status: RevocationTierStatus.`open`
        )
    }
}
