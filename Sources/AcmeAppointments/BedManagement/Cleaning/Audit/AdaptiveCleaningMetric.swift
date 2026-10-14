import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive cleaning metric is in its life cycle.
    enum AdaptiveCleaningMetricStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a adaptive cleaning metric and its current status.
    final class AdaptiveCleaningMetric {
        var code: String
        var name: String
        var version: Int
        var attributes: [String: String]
        var pinned: Bool
        var status: AdaptiveCleaningMetricStatus

        init(code: String, name: String, version: Int, attributes: [String: String], pinned: Bool, status: AdaptiveCleaningMetricStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.attributes = attributes
            self.pinned = pinned
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

        func canMoveTo(_ next: AdaptiveCleaningMetricStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == AdaptiveCleaningMetricStatus.stopped
            case .ready:
                return next == AdaptiveCleaningMetricStatus.draining || next == AdaptiveCleaningMetricStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: AdaptiveCleaningMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive cleaning metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("adaptive cleaning metric") \(code)"
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

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> AdaptiveCleaningMetric {
            return AdaptiveCleaningMetric(
                code: code,
                name: name,
                version: version,
                attributes: attributes,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive cleaning metric in status idle.
    static func newAdaptiveCleaningMetric(_ code: String, name: String) -> AdaptiveCleaningMetric {
        return AdaptiveCleaningMetric(
            code: code,
            name: name,
            version: 0,
            attributes: [:],
            pinned: false,
            status: AdaptiveCleaningMetricStatus.idle
        )
    }
}
