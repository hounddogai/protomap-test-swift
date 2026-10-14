import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial entry is in its life cycle.
    enum DenialEntryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One denial entry, with what the planners need to act on it.
    final class DenialEntry {
        var code: String
        var title: String
        var windowDays: Int
        var batchSize: Int
        var expiresAt: Int
        var copay: Double
        var weight: Double
        var status: DenialEntryStatus

        init(code: String, title: String, windowDays: Int, batchSize: Int, expiresAt: Int, copay: Double, weight: Double, status: DenialEntryStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.batchSize = batchSize
            self.expiresAt = expiresAt
            self.copay = copay
            self.weight = weight
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

        func canMoveTo(_ next: DenialEntryStatus) -> Bool {
            switch status {
            case .planned:
                return next == DenialEntryStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == DenialEntryStatus.completed || next == DenialEntryStatus.cancelled
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

        func moveTo(_ next: DenialEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedExposure() -> Double {
            return (weight * copay * 100).rounded() / 100
        }

        func copyValue() -> DenialEntry {
            return DenialEntry(
                code: code,
                title: title,
                windowDays: windowDays,
                batchSize: batchSize,
                expiresAt: expiresAt,
                copay: copay,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a denial entry in status planned.
    static func newDenialEntry(_ code: String, title: String) -> DenialEntry {
        return DenialEntry(
            code: code,
            title: title,
            windowDays: 0,
            batchSize: 0,
            expiresAt: 0,
            copay: 0.0,
            weight: 0.0,
            status: DenialEntryStatus.planned
        )
    }
}
