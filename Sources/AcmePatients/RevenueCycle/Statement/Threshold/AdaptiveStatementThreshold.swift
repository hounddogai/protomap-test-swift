import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a adaptive statement threshold is in its life cycle.
    enum AdaptiveStatementThresholdStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One adaptive statement threshold, with what the planners need to act on it.
    final class AdaptiveStatementThreshold {
        var code: String
        var label: String
        var retries: Int
        var capacity: Int
        var tags: [String]
        var timezone: String
        var status: AdaptiveStatementThresholdStatus

        init(code: String, label: String, retries: Int, capacity: Int, tags: [String], timezone: String, status: AdaptiveStatementThresholdStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.capacity = capacity
            self.tags = tags
            self.timezone = timezone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveStatementThresholdStatus) -> Bool {
            switch status {
            case .new:
                return next == AdaptiveStatementThresholdStatus.done
            case .queued:
                return next == AdaptiveStatementThresholdStatus.running || next == AdaptiveStatementThresholdStatus.failed
            case .running:
                return next == AdaptiveStatementThresholdStatus.done || next == AdaptiveStatementThresholdStatus.failed
            case .done:
                return next == AdaptiveStatementThresholdStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveStatementThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive statement threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("adaptive statement threshold") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveValue() -> Double {
            return ((Double(retries) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveStatementThreshold {
            return AdaptiveStatementThreshold(
                code: code,
                label: label,
                retries: retries,
                capacity: capacity,
                tags: tags,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive statement threshold in status new.
    static func newAdaptiveStatementThreshold(_ code: String, label: String) -> AdaptiveStatementThreshold {
        return AdaptiveStatementThreshold(
            code: code,
            label: label,
            retries: 0,
            capacity: 0,
            tags: [],
            timezone: "",
            status: AdaptiveStatementThresholdStatus.new
        )
    }
}
