import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a tiered claim metric is in its life cycle.
    enum TieredClaimMetricStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a tiered claim metric and its current status.
    final class TieredClaimMetric {
        var code: String
        var title: String
        var region: String
        var updatedAt: Int
        var createdAt: Int
        var priority: Int
        var capacity: Int
        var category: String
        var channel: String
        var visible: Bool
        var status: TieredClaimMetricStatus

        init(code: String, title: String, region: String, updatedAt: Int, createdAt: Int, priority: Int, capacity: Int, category: String, channel: String, visible: Bool, status: TieredClaimMetricStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.updatedAt = updatedAt
            self.createdAt = createdAt
            self.priority = priority
            self.capacity = capacity
            self.category = category
            self.channel = channel
            self.visible = visible
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

        func canMoveTo(_ next: TieredClaimMetricStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: TieredClaimMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered claim metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedExposure() -> Double {
            return ((Double(updatedAt) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> TieredClaimMetric {
            return TieredClaimMetric(
                code: code,
                title: title,
                region: region,
                updatedAt: updatedAt,
                createdAt: createdAt,
                priority: priority,
                capacity: capacity,
                category: category,
                channel: channel,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a tiered claim metric in status open.
    static func newTieredClaimMetric(_ code: String, title: String) -> TieredClaimMetric {
        return TieredClaimMetric(
            code: code,
            title: title,
            region: "",
            updatedAt: 0,
            createdAt: 0,
            priority: 0,
            capacity: 0,
            category: "",
            channel: "",
            visible: false,
            status: TieredClaimMetricStatus.`open`
        )
    }
}
