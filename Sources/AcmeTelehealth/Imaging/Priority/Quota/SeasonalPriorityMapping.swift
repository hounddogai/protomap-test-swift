import AcmePlatform
import Foundation

extension Imaging {
    /// Where a seasonal priority mapping is in its life cycle.
    enum SeasonalPriorityMappingStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A seasonal priority mapping as the priority team keeps it.
    final class SeasonalPriorityMapping {
        var code: String
        var name: String
        var channel: String
        var ownerID: String
        var createdAt: Int
        var category: String
        var segment: String
        var discount: Double
        var locale: String
        var status: SeasonalPriorityMappingStatus

        init(code: String, name: String, channel: String, ownerID: String, createdAt: Int, category: String, segment: String, discount: Double, locale: String, status: SeasonalPriorityMappingStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.ownerID = ownerID
            self.createdAt = createdAt
            self.category = category
            self.segment = segment
            self.discount = discount
            self.locale = locale
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

        func canMoveTo(_ next: SeasonalPriorityMappingStatus) -> Bool {
            switch status {
            case .planned:
                return next == SeasonalPriorityMappingStatus.completed
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: SeasonalPriorityMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal priority mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("seasonal priority mapping") \(code)"
        }

        func effectiveLoad() -> Double {
            return (discount * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalPriorityMapping {
            return SeasonalPriorityMapping(
                code: code,
                name: name,
                channel: channel,
                ownerID: ownerID,
                createdAt: createdAt,
                category: category,
                segment: segment,
                discount: discount,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a seasonal priority mapping in status planned.
    static func newSeasonalPriorityMapping(_ code: String, name: String) -> SeasonalPriorityMapping {
        return SeasonalPriorityMapping(
            code: code,
            name: name,
            channel: "",
            ownerID: "",
            createdAt: 0,
            category: "",
            segment: "",
            discount: 0.0,
            locale: "",
            status: SeasonalPriorityMappingStatus.planned
        )
    }
}
