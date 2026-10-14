import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool assignment is in its life cycle.
    enum FloatPoolAssignmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A float pool assignment as the float pool team keeps it.
    final class FloatPoolAssignment {
        var code: String
        var title: String
        var archived: Bool
        var score: Double
        var retries: Int
        var tags: [String]
        var budget: Double
        var status: FloatPoolAssignmentStatus

        init(code: String, title: String, archived: Bool, score: Double, retries: Int, tags: [String], budget: Double, status: FloatPoolAssignmentStatus) {
            self.code = code
            self.title = title
            self.archived = archived
            self.score = score
            self.retries = retries
            self.tags = tags
            self.budget = budget
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FloatPoolAssignmentStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: FloatPoolAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveVolume() -> Double {
            return ((score + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolAssignment {
            return FloatPoolAssignment(
                code: code,
                title: title,
                archived: archived,
                score: score,
                retries: retries,
                tags: tags,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a float pool assignment in status requested.
    static func newFloatPoolAssignment(_ code: String, title: String) -> FloatPoolAssignment {
        return FloatPoolAssignment(
            code: code,
            title: title,
            archived: false,
            score: 0.0,
            retries: 0,
            tags: [],
            budget: 0.0,
            status: FloatPoolAssignmentStatus.requested
        )
    }
}
