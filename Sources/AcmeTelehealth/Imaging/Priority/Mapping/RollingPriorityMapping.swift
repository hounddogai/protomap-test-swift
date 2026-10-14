import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling priority mapping is in its life cycle.
    enum RollingPriorityMappingStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a rolling priority mapping and its current status.
    final class RollingPriorityMapping {
        var code: String
        var label: String
        var reviewer: String
        var category: String
        var maximum: Double
        var encounterID: String
        var limit: Int
        var locale: String
        var status: RollingPriorityMappingStatus

        init(code: String, label: String, reviewer: String, category: String, maximum: Double, encounterID: String, limit: Int, locale: String, status: RollingPriorityMappingStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.category = category
            self.maximum = maximum
            self.encounterID = encounterID
            self.limit = limit
            self.locale = locale
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingPriorityMappingStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == RollingPriorityMappingStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == RollingPriorityMappingStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingPriorityMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling priority mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("rolling priority mapping") \(code)"
        }

        func projectedExposure() -> Double {
            return (Double(limit) * maximum * 100).rounded() / 100
        }

        func copyValue() -> RollingPriorityMapping {
            return RollingPriorityMapping(
                code: code,
                label: label,
                reviewer: reviewer,
                category: category,
                maximum: maximum,
                encounterID: encounterID,
                limit: limit,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a rolling priority mapping in status idle.
    static func newRollingPriorityMapping(_ code: String, label: String) -> RollingPriorityMapping {
        return RollingPriorityMapping(
            code: code,
            label: label,
            reviewer: "",
            category: "",
            maximum: 0.0,
            encounterID: "",
            limit: 0,
            locale: "",
            status: RollingPriorityMappingStatus.idle
        )
    }
}
