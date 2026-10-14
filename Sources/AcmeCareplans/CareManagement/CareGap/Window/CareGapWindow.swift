import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap window is in its life cycle.
    enum CareGapWindowStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A care gap window as the care gap team keeps it.
    final class CareGapWindow {
        var code: String
        var name: String
        var timezone: String
        var windowDays: Int
        var active: Bool
        var ownerID: String
        var startsAt: Int
        var threshold: Double
        var graceDays: Int
        var status: CareGapWindowStatus

        init(code: String, name: String, timezone: String, windowDays: Int, active: Bool, ownerID: String, startsAt: Int, threshold: Double, graceDays: Int, status: CareGapWindowStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.windowDays = windowDays
            self.active = active
            self.ownerID = ownerID
            self.startsAt = startsAt
            self.threshold = threshold
            self.graceDays = graceDays
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

        func canMoveTo(_ next: CareGapWindowStatus) -> Bool {
            switch status {
            case .`open`:
                return next == CareGapWindowStatus.archived
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == CareGapWindowStatus.archived
            case .reopened:
                return next == CareGapWindowStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netValue() -> Double {
            return ((Double(windowDays) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> CareGapWindow {
            return CareGapWindow(
                code: code,
                name: name,
                timezone: timezone,
                windowDays: windowDays,
                active: active,
                ownerID: ownerID,
                startsAt: startsAt,
                threshold: threshold,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a care gap window in status open.
    static func newCareGapWindow(_ code: String, name: String) -> CareGapWindow {
        return CareGapWindow(
            code: code,
            name: name,
            timezone: "",
            windowDays: 0,
            active: false,
            ownerID: "",
            startsAt: 0,
            threshold: 0.0,
            graceDays: 0,
            status: CareGapWindowStatus.`open`
        )
    }
}
