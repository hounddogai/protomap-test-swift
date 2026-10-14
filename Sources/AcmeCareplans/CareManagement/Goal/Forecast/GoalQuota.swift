import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal quota is in its life cycle.
    enum GoalQuotaStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A goal quota. Its code is unique within a tenant.
    final class GoalQuota {
        var code: String
        var label: String
        var tags: [String]
        var visible: Bool
        var locale: String
        var graceDays: Int
        var status: GoalQuotaStatus

        init(code: String, label: String, tags: [String], visible: Bool, locale: String, graceDays: Int, status: GoalQuotaStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.visible = visible
            self.locale = locale
            self.graceDays = graceDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GoalQuotaStatus) -> Bool {
            switch status {
            case .new:
                return next == GoalQuotaStatus.queued || next == GoalQuotaStatus.failed
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == GoalQuotaStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GoalQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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
            return Double(graceDays)
        }

        func copyValue() -> GoalQuota {
            return GoalQuota(
                code: code,
                label: label,
                tags: tags,
                visible: visible,
                locale: locale,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a goal quota in status new.
    static func newGoalQuota(_ code: String, label: String) -> GoalQuota {
        return GoalQuota(
            code: code,
            label: label,
            tags: [],
            visible: false,
            locale: "",
            graceDays: 0,
            status: GoalQuotaStatus.new
        )
    }
}
