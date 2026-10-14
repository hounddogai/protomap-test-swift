import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal preference is in its life cycle.
    enum GoalPreferenceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A goal preference as the goal team keeps it.
    final class GoalPreference {
        var code: String
        var title: String
        var description: String
        var tags: [String]
        var source: String
        var floorValue: Double
        var status: GoalPreferenceStatus

        init(code: String, title: String, description: String, tags: [String], source: String, floorValue: Double, status: GoalPreferenceStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.tags = tags
            self.source = source
            self.floorValue = floorValue
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

        func canMoveTo(_ next: GoalPreferenceStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == GoalPreferenceStatus.published || next == GoalPreferenceStatus.retired
            case .published:
                return next == GoalPreferenceStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GoalPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("goal preference") \(code)"
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
            return floorValue
        }

        func copyValue() -> GoalPreference {
            return GoalPreference(
                code: code,
                title: title,
                description: description,
                tags: tags,
                source: source,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a goal preference in status created.
    static func newGoalPreference(_ code: String, title: String) -> GoalPreference {
        return GoalPreference(
            code: code,
            title: title,
            description: "",
            tags: [],
            source: "",
            floorValue: 0.0,
            status: GoalPreferenceStatus.created
        )
    }
}
