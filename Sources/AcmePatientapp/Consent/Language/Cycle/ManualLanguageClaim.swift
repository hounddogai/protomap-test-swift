import AcmePlatform
import Foundation

extension Consent {
    /// Where a manual language claim is in its life cycle.
    enum ManualLanguageClaimStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One manual language claim, with what the planners need to act on it.
    final class ManualLanguageClaim {
        var code: String
        var label: String
        var active: Bool
        var budget: Double
        var archived: Bool
        var windowDays: Int
        var endsAt: Int
        var timezone: String
        var checksum: String
        var source: String
        var status: ManualLanguageClaimStatus

        init(code: String, label: String, active: Bool, budget: Double, archived: Bool, windowDays: Int, endsAt: Int, timezone: String, checksum: String, source: String, status: ManualLanguageClaimStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.budget = budget
            self.archived = archived
            self.windowDays = windowDays
            self.endsAt = endsAt
            self.timezone = timezone
            self.checksum = checksum
            self.source = source
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

        func canMoveTo(_ next: ManualLanguageClaimStatus) -> Bool {
            switch status {
            case .planned:
                return next == ManualLanguageClaimStatus.completed
            case .scheduled:
                return next == ManualLanguageClaimStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ManualLanguageClaimStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualLanguageClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual language claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveLoad() -> Double {
            return ((Double(windowDays) + budget) * 100).rounded() / 100
        }

        func copyValue() -> ManualLanguageClaim {
            return ManualLanguageClaim(
                code: code,
                label: label,
                active: active,
                budget: budget,
                archived: archived,
                windowDays: windowDays,
                endsAt: endsAt,
                timezone: timezone,
                checksum: checksum,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a manual language claim in status planned.
    static func newManualLanguageClaim(_ code: String, label: String) -> ManualLanguageClaim {
        return ManualLanguageClaim(
            code: code,
            label: label,
            active: false,
            budget: 0.0,
            archived: false,
            windowDays: 0,
            endsAt: 0,
            timezone: "",
            checksum: "",
            source: "",
            status: ManualLanguageClaimStatus.planned
        )
    }
}
