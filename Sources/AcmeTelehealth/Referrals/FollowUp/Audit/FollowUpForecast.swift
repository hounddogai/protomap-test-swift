import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up forecast is in its life cycle.
    enum FollowUpForecastStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a follow up forecast and its current status.
    final class FollowUpForecast {
        var code: String
        var title: String
        var ceiling: Double
        var ownerID: String
        var amount: Double
        var notes: String
        var visitMinutes: Int
        var capacity: Int
        var reviewer: String
        var attributes: [String: String]
        var facility: String
        var status: FollowUpForecastStatus

        init(code: String, title: String, ceiling: Double, ownerID: String, amount: Double, notes: String, visitMinutes: Int, capacity: Int, reviewer: String, attributes: [String: String], facility: String, status: FollowUpForecastStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.ownerID = ownerID
            self.amount = amount
            self.notes = notes
            self.visitMinutes = visitMinutes
            self.capacity = capacity
            self.reviewer = reviewer
            self.attributes = attributes
            self.facility = facility
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FollowUpForecastStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == FollowUpForecastStatus.inProgress
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == FollowUpForecastStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func weightedVolume() -> Double {
            return ((Double(capacity) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpForecast {
            return FollowUpForecast(
                code: code,
                title: title,
                ceiling: ceiling,
                ownerID: ownerID,
                amount: amount,
                notes: notes,
                visitMinutes: visitMinutes,
                capacity: capacity,
                reviewer: reviewer,
                attributes: attributes,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a follow up forecast in status planned.
    static func newFollowUpForecast(_ code: String, title: String) -> FollowUpForecast {
        return FollowUpForecast(
            code: code,
            title: title,
            ceiling: 0.0,
            ownerID: "",
            amount: 0.0,
            notes: "",
            visitMinutes: 0,
            capacity: 0,
            reviewer: "",
            attributes: [:],
            facility: "",
            status: FollowUpForecastStatus.planned
        )
    }
}
