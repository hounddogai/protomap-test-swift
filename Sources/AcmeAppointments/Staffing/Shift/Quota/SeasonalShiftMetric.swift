import AcmePlatform
import Foundation

extension Staffing {
    /// Where a seasonal shift metric is in its life cycle.
    enum SeasonalShiftMetricStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a seasonal shift metric and its current status.
    final class SeasonalShiftMetric {
        var code: String
        var name: String
        var expiresAt: Int
        var budget: Double
        var title: String
        var sequence: Int
        var status: SeasonalShiftMetricStatus

        init(code: String, name: String, expiresAt: Int, budget: Double, title: String, sequence: Int, status: SeasonalShiftMetricStatus) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.budget = budget
            self.title = title
            self.sequence = sequence
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

        func canMoveTo(_ next: SeasonalShiftMetricStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == SeasonalShiftMetricStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalShiftMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal shift metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveLoad() -> Double {
            return ((Double(expiresAt) - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalShiftMetric {
            return SeasonalShiftMetric(
                code: code,
                name: name,
                expiresAt: expiresAt,
                budget: budget,
                title: title,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal shift metric in status idle.
    static func newSeasonalShiftMetric(_ code: String, name: String) -> SeasonalShiftMetric {
        return SeasonalShiftMetric(
            code: code,
            name: name,
            expiresAt: 0,
            budget: 0.0,
            title: "",
            sequence: 0,
            status: SeasonalShiftMetricStatus.idle
        )
    }
}
