import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning window is in its life cycle.
    enum CleaningWindowStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A cleaning window. Its code is unique within a tenant.
    final class CleaningWindow {
        var code: String
        var title: String
        var bed: String
        var checksum: String
        var threshold: Double
        var endsAt: Int
        var status: CleaningWindowStatus

        init(code: String, title: String, bed: String, checksum: String, threshold: Double, endsAt: Int, status: CleaningWindowStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.checksum = checksum
            self.threshold = threshold
            self.endsAt = endsAt
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

        func canMoveTo(_ next: CleaningWindowStatus) -> Bool {
            switch status {
            case .`open`:
                return next == CleaningWindowStatus.resolved
            case .inReview:
                return next == CleaningWindowStatus.resolved || next == CleaningWindowStatus.archived
            case .resolved:
                return next == CleaningWindowStatus.reopened || next == CleaningWindowStatus.archived
            case .reopened:
                return next == CleaningWindowStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CleaningWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("cleaning window") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((threshold + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> CleaningWindow {
            return CleaningWindow(
                code: code,
                title: title,
                bed: bed,
                checksum: checksum,
                threshold: threshold,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a cleaning window in status open.
    static func newCleaningWindow(_ code: String, title: String) -> CleaningWindow {
        return CleaningWindow(
            code: code,
            title: title,
            bed: "",
            checksum: "",
            threshold: 0.0,
            endsAt: 0,
            status: CleaningWindowStatus.`open`
        )
    }
}
