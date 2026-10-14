import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a legacy authorization entry is in its life cycle.
    enum LegacyAuthorizationEntryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One legacy authorization entry, with what the planners need to act on it.
    final class LegacyAuthorizationEntry {
        var code: String
        var label: String
        var startsAt: Int
        var ratio: Double
        var visitMinutes: Int
        var status: LegacyAuthorizationEntryStatus

        init(code: String, label: String, startsAt: Int, ratio: Double, visitMinutes: Int, status: LegacyAuthorizationEntryStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.ratio = ratio
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: LegacyAuthorizationEntryStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == LegacyAuthorizationEntryStatus.published
            case .published:
                return next == LegacyAuthorizationEntryStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyAuthorizationEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy authorization entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveTotal() -> Double {
            return ((Double(visitMinutes) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyAuthorizationEntry {
            return LegacyAuthorizationEntry(
                code: code,
                label: label,
                startsAt: startsAt,
                ratio: ratio,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy authorization entry in status created.
    static func newLegacyAuthorizationEntry(_ code: String, label: String) -> LegacyAuthorizationEntry {
        return LegacyAuthorizationEntry(
            code: code,
            label: label,
            startsAt: 0,
            ratio: 0.0,
            visitMinutes: 0,
            status: LegacyAuthorizationEntryStatus.created
        )
    }
}
