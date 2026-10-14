import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning override is in its life cycle.
    enum CleaningOverrideStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One cleaning override, with what the planners need to act on it.
    final class CleaningOverride {
        var code: String
        var label: String
        var pinned: Bool
        var locale: String
        var quantity: Int
        var archived: Bool
        var startsAt: Int
        var status: CleaningOverrideStatus

        init(code: String, label: String, pinned: Bool, locale: String, quantity: Int, archived: Bool, startsAt: Int, status: CleaningOverrideStatus) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.locale = locale
            self.quantity = quantity
            self.archived = archived
            self.startsAt = startsAt
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

        func canMoveTo(_ next: CleaningOverrideStatus) -> Bool {
            switch status {
            case .`open`:
                return next == CleaningOverrideStatus.reopened || next == CleaningOverrideStatus.archived
            case .inReview:
                return next == CleaningOverrideStatus.resolved
            case .resolved:
                return next == CleaningOverrideStatus.archived
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

        func moveTo(_ next: CleaningOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("cleaning override") \(code)"
        }

        func projectedLoad() -> Double {
            return ((Double(quantity) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> CleaningOverride {
            return CleaningOverride(
                code: code,
                label: label,
                pinned: pinned,
                locale: locale,
                quantity: quantity,
                archived: archived,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a cleaning override in status open.
    static func newCleaningOverride(_ code: String, label: String) -> CleaningOverride {
        return CleaningOverride(
            code: code,
            label: label,
            pinned: false,
            locale: "",
            quantity: 0,
            archived: false,
            startsAt: 0,
            status: CleaningOverrideStatus.`open`
        )
    }
}
