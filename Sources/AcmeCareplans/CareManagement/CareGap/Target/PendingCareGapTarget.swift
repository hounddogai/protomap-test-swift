import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a pending care gap target is in its life cycle.
    enum PendingCareGapTargetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A pending care gap target as the care gap team keeps it.
    final class PendingCareGapTarget {
        var code: String
        var label: String
        var batchSize: Int
        var attributes: [String: String]
        var title: String
        var timezone: String
        var maximum: Double
        var status: PendingCareGapTargetStatus

        init(code: String, label: String, batchSize: Int, attributes: [String: String], title: String, timezone: String, maximum: Double, status: PendingCareGapTargetStatus) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.attributes = attributes
            self.title = title
            self.timezone = timezone
            self.maximum = maximum
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

        func canMoveTo(_ next: PendingCareGapTargetStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == PendingCareGapTargetStatus.ready || next == PendingCareGapTargetStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PendingCareGapTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending care gap target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("pending care gap target") \(code)"
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

        func netExposure() -> Double {
            return ((Double(batchSize) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> PendingCareGapTarget {
            return PendingCareGapTarget(
                code: code,
                label: label,
                batchSize: batchSize,
                attributes: attributes,
                title: title,
                timezone: timezone,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending care gap target in status idle.
    static func newPendingCareGapTarget(_ code: String, label: String) -> PendingCareGapTarget {
        return PendingCareGapTarget(
            code: code,
            label: label,
            batchSize: 0,
            attributes: [:],
            title: "",
            timezone: "",
            maximum: 0.0,
            status: PendingCareGapTargetStatus.idle
        )
    }
}
