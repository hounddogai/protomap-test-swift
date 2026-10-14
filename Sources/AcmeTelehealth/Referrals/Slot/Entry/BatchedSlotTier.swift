import AcmePlatform
import Foundation

extension Referrals {
    /// Where a batched slot tier is in its life cycle.
    enum BatchedSlotTierStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A batched slot tier. Its code is unique within a tenant.
    final class BatchedSlotTier {
        var code: String
        var title: String
        var locale: String
        var contactEmail: String
        var expiresAt: Int
        var durationMinutes: Int
        var label: String
        var threshold: Double
        var ward: String
        var rate: Double
        var status: BatchedSlotTierStatus

        init(code: String, title: String, locale: String, contactEmail: String, expiresAt: Int, durationMinutes: Int, label: String, threshold: Double, ward: String, rate: Double, status: BatchedSlotTierStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.contactEmail = contactEmail
            self.expiresAt = expiresAt
            self.durationMinutes = durationMinutes
            self.label = label
            self.threshold = threshold
            self.ward = ward
            self.rate = rate
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

        func canMoveTo(_ next: BatchedSlotTierStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == BatchedSlotTierStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedSlotTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched slot tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(title)"
        }

        func effectiveExposure() -> Double {
            return (rate * threshold * 100).rounded() / 100
        }

        func copyValue() -> BatchedSlotTier {
            return BatchedSlotTier(
                code: code,
                title: title,
                locale: locale,
                contactEmail: contactEmail,
                expiresAt: expiresAt,
                durationMinutes: durationMinutes,
                label: label,
                threshold: threshold,
                ward: ward,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a batched slot tier in status created.
    static func newBatchedSlotTier(_ code: String, title: String) -> BatchedSlotTier {
        return BatchedSlotTier(
            code: code,
            title: title,
            locale: "",
            contactEmail: "",
            expiresAt: 0,
            durationMinutes: 0,
            label: "",
            threshold: 0.0,
            ward: "",
            rate: 0.0,
            status: BatchedSlotTierStatus.created
        )
    }
}
