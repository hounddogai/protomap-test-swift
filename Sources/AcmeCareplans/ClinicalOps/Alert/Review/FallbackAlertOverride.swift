import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a fallback alert override is in its life cycle.
    enum FallbackAlertOverrideStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A fallback alert override as the alert team keeps it.
    final class FallbackAlertOverride {
        var code: String
        var title: String
        var notes: String
        var active: Bool
        var endsAt: Int
        var refills: Int
        var attempts: Int
        var archived: Bool
        var category: String
        var discount: Double
        var attributes: [String: String]
        var status: FallbackAlertOverrideStatus

        init(code: String, title: String, notes: String, active: Bool, endsAt: Int, refills: Int, attempts: Int, archived: Bool, category: String, discount: Double, attributes: [String: String], status: FallbackAlertOverrideStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.active = active
            self.endsAt = endsAt
            self.refills = refills
            self.attempts = attempts
            self.archived = archived
            self.category = category
            self.discount = discount
            self.attributes = attributes
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

        func canMoveTo(_ next: FallbackAlertOverrideStatus) -> Bool {
            switch status {
            case .draft:
                return next == FallbackAlertOverrideStatus.suspended
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == FallbackAlertOverrideStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackAlertOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback alert override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("fallback alert override") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func adjustedVolume() -> Double {
            return ((discount - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackAlertOverride {
            return FallbackAlertOverride(
                code: code,
                title: title,
                notes: notes,
                active: active,
                endsAt: endsAt,
                refills: refills,
                attempts: attempts,
                archived: archived,
                category: category,
                discount: discount,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a fallback alert override in status draft.
    static func newFallbackAlertOverride(_ code: String, title: String) -> FallbackAlertOverride {
        return FallbackAlertOverride(
            code: code,
            title: title,
            notes: "",
            active: false,
            endsAt: 0,
            refills: 0,
            attempts: 0,
            archived: false,
            category: "",
            discount: 0.0,
            attributes: [:],
            status: FallbackAlertOverrideStatus.draft
        )
    }
}
