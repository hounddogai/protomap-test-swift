import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix request is in its life cycle.
    enum SkillMixRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a skill mix request and its current status.
    final class SkillMixRequest {
        var code: String
        var name: String
        var ward: String
        var archived: Bool
        var category: String
        var ceiling: Double
        var maximum: Double
        var status: SkillMixRequestStatus

        init(code: String, name: String, ward: String, archived: Bool, category: String, ceiling: Double, maximum: Double, status: SkillMixRequestStatus) {
            self.code = code
            self.name = name
            self.ward = ward
            self.archived = archived
            self.category = category
            self.ceiling = ceiling
            self.maximum = maximum
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

        func canMoveTo(_ next: SkillMixRequestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == SkillMixRequestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SkillMixRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedVolume() -> Double {
            return ((ceiling - maximum) * 100).rounded() / 100
        }

        func copyValue() -> SkillMixRequest {
            return SkillMixRequest(
                code: code,
                name: name,
                ward: ward,
                archived: archived,
                category: category,
                ceiling: ceiling,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a skill mix request in status draft.
    static func newSkillMixRequest(_ code: String, name: String) -> SkillMixRequest {
        return SkillMixRequest(
            code: code,
            name: name,
            ward: "",
            archived: false,
            category: "",
            ceiling: 0.0,
            maximum: 0.0,
            status: SkillMixRequestStatus.draft
        )
    }
}
