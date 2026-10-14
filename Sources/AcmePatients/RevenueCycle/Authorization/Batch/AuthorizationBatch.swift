import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization batch is in its life cycle.
    enum AuthorizationBatchStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A authorization batch as the authorization team keeps it.
    final class AuthorizationBatch {
        var code: String
        var title: String
        var reviewer: String
        var sequence: Int
        var floorValue: Double
        var description: String
        var tags: [String]
        var summary: String
        var source: String
        var segment: String
        var status: AuthorizationBatchStatus

        init(code: String, title: String, reviewer: String, sequence: Int, floorValue: Double, description: String, tags: [String], summary: String, source: String, segment: String, status: AuthorizationBatchStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.sequence = sequence
            self.floorValue = floorValue
            self.description = description
            self.tags = tags
            self.summary = summary
            self.source = source
            self.segment = segment
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

        func canMoveTo(_ next: AuthorizationBatchStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == AuthorizationBatchStatus.suspended
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: AuthorizationBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveTotal() -> Double {
            return ((floorValue + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationBatch {
            return AuthorizationBatch(
                code: code,
                title: title,
                reviewer: reviewer,
                sequence: sequence,
                floorValue: floorValue,
                description: description,
                tags: tags,
                summary: summary,
                source: source,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a authorization batch in status draft.
    static func newAuthorizationBatch(_ code: String, title: String) -> AuthorizationBatch {
        return AuthorizationBatch(
            code: code,
            title: title,
            reviewer: "",
            sequence: 0,
            floorValue: 0.0,
            description: "",
            tags: [],
            summary: "",
            source: "",
            segment: "",
            status: AuthorizationBatchStatus.draft
        )
    }
}
