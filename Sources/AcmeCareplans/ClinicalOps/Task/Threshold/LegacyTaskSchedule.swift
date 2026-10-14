import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a legacy task schedule is in its life cycle.
    enum LegacyTaskScheduleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A legacy task schedule. Its code is unique within a tenant.
    final class LegacyTaskSchedule {
        var code: String
        var title: String
        var ownerID: String
        var limit: Int
        var source: String
        var tags: [String]
        var quantity: Int
        var priority: Int
        var budget: Double
        var description: String
        var facility: String
        var status: LegacyTaskScheduleStatus

        init(code: String, title: String, ownerID: String, limit: Int, source: String, tags: [String], quantity: Int, priority: Int, budget: Double, description: String, facility: String, status: LegacyTaskScheduleStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.limit = limit
            self.source = source
            self.tags = tags
            self.quantity = quantity
            self.priority = priority
            self.budget = budget
            self.description = description
            self.facility = facility
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

        func canMoveTo(_ next: LegacyTaskScheduleStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
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

        func moveTo(_ next: LegacyTaskScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy task schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy task schedule") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedValue() -> Double {
            return ((Double(limit) - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyTaskSchedule {
            return LegacyTaskSchedule(
                code: code,
                title: title,
                ownerID: ownerID,
                limit: limit,
                source: source,
                tags: tags,
                quantity: quantity,
                priority: priority,
                budget: budget,
                description: description,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a legacy task schedule in status created.
    static func newLegacyTaskSchedule(_ code: String, title: String) -> LegacyTaskSchedule {
        return LegacyTaskSchedule(
            code: code,
            title: title,
            ownerID: "",
            limit: 0,
            source: "",
            tags: [],
            quantity: 0,
            priority: 0,
            budget: 0.0,
            description: "",
            facility: "",
            status: LegacyTaskScheduleStatus.created
        )
    }
}
