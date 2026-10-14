import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan schedule is in its life cycle.
    enum DischargePlanScheduleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One discharge plan schedule, with what the planners need to act on it.
    final class DischargePlanSchedule {
        var code: String
        var title: String
        var weight: Double
        var attributes: [String: String]
        var attempts: Int
        var externalRef: String
        var category: String
        var locale: String
        var ratio: Double
        var capacity: Int
        var status: DischargePlanScheduleStatus

        init(code: String, title: String, weight: Double, attributes: [String: String], attempts: Int, externalRef: String, category: String, locale: String, ratio: Double, capacity: Int, status: DischargePlanScheduleStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.attributes = attributes
            self.attempts = attempts
            self.externalRef = externalRef
            self.category = category
            self.locale = locale
            self.ratio = ratio
            self.capacity = capacity
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

        func canMoveTo(_ next: DischargePlanScheduleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == DischargePlanScheduleStatus.reopened || next == DischargePlanScheduleStatus.archived
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == DischargePlanScheduleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DischargePlanScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
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

        func effectiveTotal() -> Double {
            return ((Double(capacity) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanSchedule {
            return DischargePlanSchedule(
                code: code,
                title: title,
                weight: weight,
                attributes: attributes,
                attempts: attempts,
                externalRef: externalRef,
                category: category,
                locale: locale,
                ratio: ratio,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a discharge plan schedule in status open.
    static func newDischargePlanSchedule(_ code: String, title: String) -> DischargePlanSchedule {
        return DischargePlanSchedule(
            code: code,
            title: title,
            weight: 0.0,
            attributes: [:],
            attempts: 0,
            externalRef: "",
            category: "",
            locale: "",
            ratio: 0.0,
            capacity: 0,
            status: DischargePlanScheduleStatus.`open`
        )
    }
}
