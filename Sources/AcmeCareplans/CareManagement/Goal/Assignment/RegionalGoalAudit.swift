import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a regional goal audit is in its life cycle.
    enum RegionalGoalAuditStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a regional goal audit and its current status.
    final class RegionalGoalAudit {
        var code: String
        var label: String
        var endsAt: Int
        var version: Int
        var archived: Bool
        var tags: [String]
        var pinned: Bool
        var capacity: Int
        var budget: Double
        var procedureCode: String
        var windowDays: Int
        var status: RegionalGoalAuditStatus

        init(code: String, label: String, endsAt: Int, version: Int, archived: Bool, tags: [String], pinned: Bool, capacity: Int, budget: Double, procedureCode: String, windowDays: Int, status: RegionalGoalAuditStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.version = version
            self.archived = archived
            self.tags = tags
            self.pinned = pinned
            self.capacity = capacity
            self.budget = budget
            self.procedureCode = procedureCode
            self.windowDays = windowDays
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

        func canMoveTo(_ next: RegionalGoalAuditStatus) -> Bool {
            switch status {
            case .created:
                return next == RegionalGoalAuditStatus.validated || next == RegionalGoalAuditStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RegionalGoalAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional goal audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\("regional goal audit") \(code)"
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
            return ((Double(endsAt) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalGoalAudit {
            return RegionalGoalAudit(
                code: code,
                label: label,
                endsAt: endsAt,
                version: version,
                archived: archived,
                tags: tags,
                pinned: pinned,
                capacity: capacity,
                budget: budget,
                procedureCode: procedureCode,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional goal audit in status created.
    static func newRegionalGoalAudit(_ code: String, label: String) -> RegionalGoalAudit {
        return RegionalGoalAudit(
            code: code,
            label: label,
            endsAt: 0,
            version: 0,
            archived: false,
            tags: [],
            pinned: false,
            capacity: 0,
            budget: 0.0,
            procedureCode: "",
            windowDays: 0,
            status: RegionalGoalAuditStatus.created
        )
    }
}
