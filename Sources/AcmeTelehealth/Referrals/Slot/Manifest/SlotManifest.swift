import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot manifest is in its life cycle.
    enum SlotManifestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A slot manifest. Its code is unique within a tenant.
    final class SlotManifest {
        var code: String
        var name: String
        var revision: Int
        var ceiling: Double
        var title: String
        var currency: String
        var locale: String
        var active: Bool
        var cost: Double
        var threshold: Double
        var attempts: Int
        var status: SlotManifestStatus

        init(code: String, name: String, revision: Int, ceiling: Double, title: String, currency: String, locale: String, active: Bool, cost: Double, threshold: Double, attempts: Int, status: SlotManifestStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.ceiling = ceiling
            self.title = title
            self.currency = currency
            self.locale = locale
            self.active = active
            self.cost = cost
            self.threshold = threshold
            self.attempts = attempts
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

        func canMoveTo(_ next: SlotManifestStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == SlotManifestStatus.resolved || next == SlotManifestStatus.archived
            case .resolved:
                return next == SlotManifestStatus.archived
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

        func moveTo(_ next: SlotManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedLoad() -> Double {
            return ((Double(attempts) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> SlotManifest {
            return SlotManifest(
                code: code,
                name: name,
                revision: revision,
                ceiling: ceiling,
                title: title,
                currency: currency,
                locale: locale,
                active: active,
                cost: cost,
                threshold: threshold,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a slot manifest in status open.
    static func newSlotManifest(_ code: String, name: String) -> SlotManifest {
        return SlotManifest(
            code: code,
            name: name,
            revision: 0,
            ceiling: 0.0,
            title: "",
            currency: "",
            locale: "",
            active: false,
            cost: 0.0,
            threshold: 0.0,
            attempts: 0,
            status: SlotManifestStatus.`open`
        )
    }
}
