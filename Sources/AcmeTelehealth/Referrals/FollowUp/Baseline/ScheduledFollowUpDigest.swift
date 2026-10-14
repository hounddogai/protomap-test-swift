import AcmePlatform
import Foundation

extension Referrals {
    /// Where a scheduled follow up digest is in its life cycle.
    enum ScheduledFollowUpDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A scheduled follow up digest as the follow up team keeps it.
    final class ScheduledFollowUpDigest {
        var code: String
        var label: String
        var minimum: Double
        var locale: String
        var attempts: Int
        var discount: Double
        var margin: Double
        var encounterID: String
        var expiresAt: Int
        var status: ScheduledFollowUpDigestStatus

        init(code: String, label: String, minimum: Double, locale: String, attempts: Int, discount: Double, margin: Double, encounterID: String, expiresAt: Int, status: ScheduledFollowUpDigestStatus) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.locale = locale
            self.attempts = attempts
            self.discount = discount
            self.margin = margin
            self.encounterID = encounterID
            self.expiresAt = expiresAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledFollowUpDigestStatus) -> Bool {
            switch status {
            case .new:
                return next == ScheduledFollowUpDigestStatus.failed
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == ScheduledFollowUpDigestStatus.done
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ScheduledFollowUpDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled follow up digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("scheduled follow up digest") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((Double(attempts) + margin) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledFollowUpDigest {
            return ScheduledFollowUpDigest(
                code: code,
                label: label,
                minimum: minimum,
                locale: locale,
                attempts: attempts,
                discount: discount,
                margin: margin,
                encounterID: encounterID,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a scheduled follow up digest in status new.
    static func newScheduledFollowUpDigest(_ code: String, label: String) -> ScheduledFollowUpDigest {
        return ScheduledFollowUpDigest(
            code: code,
            label: label,
            minimum: 0.0,
            locale: "",
            attempts: 0,
            discount: 0.0,
            margin: 0.0,
            encounterID: "",
            expiresAt: 0,
            status: ScheduledFollowUpDigestStatus.new
        )
    }
}
