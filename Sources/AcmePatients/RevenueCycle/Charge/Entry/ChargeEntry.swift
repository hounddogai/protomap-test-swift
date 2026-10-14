import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge entry is in its life cycle.
    enum ChargeEntryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A charge entry as the charge team keeps it.
    final class ChargeEntry {
        var code: String
        var label: String
        var endsAt: Int
        var priority: Int
        var score: Double
        var maximum: Double
        var timezone: String
        var archived: Bool
        var retries: Int
        var version: Int
        var status: ChargeEntryStatus

        init(code: String, label: String, endsAt: Int, priority: Int, score: Double, maximum: Double, timezone: String, archived: Bool, retries: Int, version: Int, status: ChargeEntryStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.priority = priority
            self.score = score
            self.maximum = maximum
            self.timezone = timezone
            self.archived = archived
            self.retries = retries
            self.version = version
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ChargeEntryStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ChargeEntryStatus.approved || next == ChargeEntryStatus.withdrawn
            case .approved:
                return next == ChargeEntryStatus.rejected
            case .rejected:
                return next == ChargeEntryStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ChargeEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveLoad() -> Double {
            return ((score + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> ChargeEntry {
            return ChargeEntry(
                code: code,
                label: label,
                endsAt: endsAt,
                priority: priority,
                score: score,
                maximum: maximum,
                timezone: timezone,
                archived: archived,
                retries: retries,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a charge entry in status proposed.
    static func newChargeEntry(_ code: String, label: String) -> ChargeEntry {
        return ChargeEntry(
            code: code,
            label: label,
            endsAt: 0,
            priority: 0,
            score: 0.0,
            maximum: 0.0,
            timezone: "",
            archived: false,
            retries: 0,
            version: 0,
            status: ChargeEntryStatus.proposed
        )
    }
}
