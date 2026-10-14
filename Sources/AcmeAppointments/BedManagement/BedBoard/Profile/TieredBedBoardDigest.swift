import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a tiered bed board digest is in its life cycle.
    enum TieredBedBoardDigestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One tiered bed board digest, with what the planners need to act on it.
    final class TieredBedBoardDigest {
        var code: String
        var name: String
        var retries: Int
        var contactEmail: String
        var margin: Double
        var externalRef: String
        var threshold: Double
        var endsAt: Int
        var updatedAt: Int
        var tags: [String]
        var status: TieredBedBoardDigestStatus

        init(code: String, name: String, retries: Int, contactEmail: String, margin: Double, externalRef: String, threshold: Double, endsAt: Int, updatedAt: Int, tags: [String], status: TieredBedBoardDigestStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.contactEmail = contactEmail
            self.margin = margin
            self.externalRef = externalRef
            self.threshold = threshold
            self.endsAt = endsAt
            self.updatedAt = updatedAt
            self.tags = tags
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

        func canMoveTo(_ next: TieredBedBoardDigestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == TieredBedBoardDigestStatus.active || next == TieredBedBoardDigestStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == TieredBedBoardDigestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredBedBoardDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered bed board digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedValue() -> Double {
            return (threshold * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> TieredBedBoardDigest {
            return TieredBedBoardDigest(
                code: code,
                name: name,
                retries: retries,
                contactEmail: contactEmail,
                margin: margin,
                externalRef: externalRef,
                threshold: threshold,
                endsAt: endsAt,
                updatedAt: updatedAt,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered bed board digest in status draft.
    static func newTieredBedBoardDigest(_ code: String, name: String) -> TieredBedBoardDigest {
        return TieredBedBoardDigest(
            code: code,
            name: name,
            retries: 0,
            contactEmail: "",
            margin: 0.0,
            externalRef: "",
            threshold: 0.0,
            endsAt: 0,
            updatedAt: 0,
            tags: [],
            status: TieredBedBoardDigestStatus.draft
        )
    }
}
