import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a tiered interaction draft is in its life cycle.
    enum TieredInteractionDraftStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a tiered interaction draft and its current status.
    final class TieredInteractionDraft {
        var code: String
        var title: String
        var createdAt: Int
        var reviewer: String
        var payer: String
        var minimum: Double
        var ownerID: String
        var revision: Int
        var tags: [String]
        var name: String
        var status: TieredInteractionDraftStatus

        init(code: String, title: String, createdAt: Int, reviewer: String, payer: String, minimum: Double, ownerID: String, revision: Int, tags: [String], name: String, status: TieredInteractionDraftStatus) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.reviewer = reviewer
            self.payer = payer
            self.minimum = minimum
            self.ownerID = ownerID
            self.revision = revision
            self.tags = tags
            self.name = name
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredInteractionDraftStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == TieredInteractionDraftStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: TieredInteractionDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered interaction draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedLoad() -> Double {
            return (minimum * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> TieredInteractionDraft {
            return TieredInteractionDraft(
                code: code,
                title: title,
                createdAt: createdAt,
                reviewer: reviewer,
                payer: payer,
                minimum: minimum,
                ownerID: ownerID,
                revision: revision,
                tags: tags,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered interaction draft in status created.
    static func newTieredInteractionDraft(_ code: String, title: String) -> TieredInteractionDraft {
        return TieredInteractionDraft(
            code: code,
            title: title,
            createdAt: 0,
            reviewer: "",
            payer: "",
            minimum: 0.0,
            ownerID: "",
            revision: 0,
            tags: [],
            name: "",
            status: TieredInteractionDraftStatus.created
        )
    }
}
