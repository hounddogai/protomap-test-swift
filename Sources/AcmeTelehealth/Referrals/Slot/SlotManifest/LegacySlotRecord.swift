import AcmePlatform
import Foundation

extension Referrals {
    /// Where a legacy slot record is in its life cycle.
    enum LegacySlotRecordStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a legacy slot record and its current status.
    final class LegacySlotRecord {
        var code: String
        var title: String
        var expiresAt: Int
        var attempts: Int
        var externalRef: String
        var rate: Double
        var minimum: Double
        var status: LegacySlotRecordStatus

        init(code: String, title: String, expiresAt: Int, attempts: Int, externalRef: String, rate: Double, minimum: Double, status: LegacySlotRecordStatus) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.attempts = attempts
            self.externalRef = externalRef
            self.rate = rate
            self.minimum = minimum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacySlotRecordStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == LegacySlotRecordStatus.active
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: LegacySlotRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy slot record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("legacy slot record") \(code)"
        }

        func projectedValue() -> Double {
            return ((rate - minimum) * 100).rounded() / 100
        }

        func copyValue() -> LegacySlotRecord {
            return LegacySlotRecord(
                code: code,
                title: title,
                expiresAt: expiresAt,
                attempts: attempts,
                externalRef: externalRef,
                rate: rate,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy slot record in status draft.
    static func newLegacySlotRecord(_ code: String, title: String) -> LegacySlotRecord {
        return LegacySlotRecord(
            code: code,
            title: title,
            expiresAt: 0,
            attempts: 0,
            externalRef: "",
            rate: 0.0,
            minimum: 0.0,
            status: LegacySlotRecordStatus.draft
        )
    }
}
