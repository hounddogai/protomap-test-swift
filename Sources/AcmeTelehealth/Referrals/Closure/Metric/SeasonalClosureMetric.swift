import AcmePlatform
import Foundation

extension Referrals {
    /// Where a seasonal closure metric is in its life cycle.
    enum SeasonalClosureMetricStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a seasonal closure metric and its current status.
    final class SeasonalClosureMetric {
        var code: String
        var name: String
        var channel: String
        var maximum: Double
        var budget: Double
        var attributes: [String: String]
        var capacity: Int
        var status: SeasonalClosureMetricStatus

        init(code: String, name: String, channel: String, maximum: Double, budget: Double, attributes: [String: String], capacity: Int, status: SeasonalClosureMetricStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.maximum = maximum
            self.budget = budget
            self.attributes = attributes
            self.capacity = capacity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalClosureMetricStatus) -> Bool {
            switch status {
            case .proposed:
                return next == SeasonalClosureMetricStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: SeasonalClosureMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal closure metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
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

        func weightedTotal() -> Double {
            return (budget * maximum * 100).rounded() / 100
        }

        func copyValue() -> SeasonalClosureMetric {
            return SeasonalClosureMetric(
                code: code,
                name: name,
                channel: channel,
                maximum: maximum,
                budget: budget,
                attributes: attributes,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a seasonal closure metric in status proposed.
    static func newSeasonalClosureMetric(_ code: String, name: String) -> SeasonalClosureMetric {
        return SeasonalClosureMetric(
            code: code,
            name: name,
            channel: "",
            maximum: 0.0,
            budget: 0.0,
            attributes: [:],
            capacity: 0,
            status: SeasonalClosureMetricStatus.proposed
        )
    }
}
