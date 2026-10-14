import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier schedule is in its life cycle.
    enum CourierScheduleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One courier schedule, with what the planners need to act on it.
    final class CourierSchedule {
        var code: String
        var name: String
        var score: Double
        var ratio: Double
        var copay: Double
        var category: String
        var externalRef: String
        var description: String
        var checksum: String
        var cost: Double
        var status: CourierScheduleStatus

        init(code: String, name: String, score: Double, ratio: Double, copay: Double, category: String, externalRef: String, description: String, checksum: String, cost: Double, status: CourierScheduleStatus) {
            self.code = code
            self.name = name
            self.score = score
            self.ratio = ratio
            self.copay = copay
            self.category = category
            self.externalRef = externalRef
            self.description = description
            self.checksum = checksum
            self.cost = cost
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

        func canMoveTo(_ next: CourierScheduleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == CourierScheduleStatus.resolved || next == CourierScheduleStatus.archived
            case .inReview:
                return next == CourierScheduleStatus.resolved
            case .resolved:
                return next == CourierScheduleStatus.reopened || next == CourierScheduleStatus.archived
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

        func moveTo(_ next: CourierScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedVolume() -> Double {
            return ((copay + score) * 100).rounded() / 100
        }

        func copyValue() -> CourierSchedule {
            return CourierSchedule(
                code: code,
                name: name,
                score: score,
                ratio: ratio,
                copay: copay,
                category: category,
                externalRef: externalRef,
                description: description,
                checksum: checksum,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a courier schedule in status open.
    static func newCourierSchedule(_ code: String, name: String) -> CourierSchedule {
        return CourierSchedule(
            code: code,
            name: name,
            score: 0.0,
            ratio: 0.0,
            copay: 0.0,
            category: "",
            externalRef: "",
            description: "",
            checksum: "",
            cost: 0.0,
            status: CourierScheduleStatus.`open`
        )
    }
}
