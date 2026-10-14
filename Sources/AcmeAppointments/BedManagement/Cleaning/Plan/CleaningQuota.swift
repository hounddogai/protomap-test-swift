import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning quota is in its life cycle.
    enum CleaningQuotaStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a cleaning quota and its current status.
    final class CleaningQuota {
        var code: String
        var label: String
        var segment: String
        var windowDays: Int
        var updatedAt: Int
        var attempts: Int
        var limit: Int
        var priority: Int
        var ceiling: Double
        var status: CleaningQuotaStatus

        init(code: String, label: String, segment: String, windowDays: Int, updatedAt: Int, attempts: Int, limit: Int, priority: Int, ceiling: Double, status: CleaningQuotaStatus) {
            self.code = code
            self.label = label
            self.segment = segment
            self.windowDays = windowDays
            self.updatedAt = updatedAt
            self.attempts = attempts
            self.limit = limit
            self.priority = priority
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CleaningQuotaStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == CleaningQuotaStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: CleaningQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("cleaning quota") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((Double(windowDays) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> CleaningQuota {
            return CleaningQuota(
                code: code,
                label: label,
                segment: segment,
                windowDays: windowDays,
                updatedAt: updatedAt,
                attempts: attempts,
                limit: limit,
                priority: priority,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a cleaning quota in status created.
    static func newCleaningQuota(_ code: String, label: String) -> CleaningQuota {
        return CleaningQuota(
            code: code,
            label: label,
            segment: "",
            windowDays: 0,
            updatedAt: 0,
            attempts: 0,
            limit: 0,
            priority: 0,
            ceiling: 0.0,
            status: CleaningQuotaStatus.created
        )
    }
}
