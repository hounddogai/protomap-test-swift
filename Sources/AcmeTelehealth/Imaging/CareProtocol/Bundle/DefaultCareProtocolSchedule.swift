import AcmePlatform
import Foundation

extension Imaging {
    /// Where a default care protocol schedule is in its life cycle.
    enum DefaultCareProtocolScheduleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A default care protocol schedule. Its code is unique within a tenant.
    final class DefaultCareProtocolSchedule {
        var code: String
        var title: String
        var budget: Double
        var category: String
        var ownerID: String
        var source: String
        var region: String
        var weight: Double
        var status: DefaultCareProtocolScheduleStatus

        init(code: String, title: String, budget: Double, category: String, ownerID: String, source: String, region: String, weight: Double, status: DefaultCareProtocolScheduleStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.category = category
            self.ownerID = ownerID
            self.source = source
            self.region = region
            self.weight = weight
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

        func canMoveTo(_ next: DefaultCareProtocolScheduleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == DefaultCareProtocolScheduleStatus.archived
            case .inReview:
                return next == DefaultCareProtocolScheduleStatus.reopened || next == DefaultCareProtocolScheduleStatus.archived
            case .resolved:
                return next == DefaultCareProtocolScheduleStatus.reopened || next == DefaultCareProtocolScheduleStatus.archived
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

        func moveTo(_ next: DefaultCareProtocolScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default care protocol schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedValue() -> Double {
            return ((weight + budget) * 100).rounded() / 100
        }

        func copyValue() -> DefaultCareProtocolSchedule {
            return DefaultCareProtocolSchedule(
                code: code,
                title: title,
                budget: budget,
                category: category,
                ownerID: ownerID,
                source: source,
                region: region,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a default care protocol schedule in status open.
    static func newDefaultCareProtocolSchedule(_ code: String, title: String) -> DefaultCareProtocolSchedule {
        return DefaultCareProtocolSchedule(
            code: code,
            title: title,
            budget: 0.0,
            category: "",
            ownerID: "",
            source: "",
            region: "",
            weight: 0.0,
            status: DefaultCareProtocolScheduleStatus.`open`
        )
    }
}
