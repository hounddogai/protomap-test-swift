import AcmePlatform
import Foundation

extension Referrals {
    /// Where a pending eligibility preference is in its life cycle.
    enum PendingEligibilityPreferenceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A pending eligibility preference. Its code is unique within a tenant.
    final class PendingEligibilityPreference {
        var code: String
        var title: String
        var phone: String
        var limit: Int
        var attributes: [String: String]
        var status: PendingEligibilityPreferenceStatus

        init(code: String, title: String, phone: String, limit: Int, attributes: [String: String], status: PendingEligibilityPreferenceStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.limit = limit
            self.attributes = attributes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingEligibilityPreferenceStatus) -> Bool {
            switch status {
            case .requested:
                return next == PendingEligibilityPreferenceStatus.granted
            case .granted:
                return next == PendingEligibilityPreferenceStatus.revoked
            case .revoked:
                return next == PendingEligibilityPreferenceStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingEligibilityPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending eligibility preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
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

        func measuredValue() -> Double {
            return Double(limit)
        }

        func copyValue() -> PendingEligibilityPreference {
            return PendingEligibilityPreference(
                code: code,
                title: title,
                phone: phone,
                limit: limit,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a pending eligibility preference in status requested.
    static func newPendingEligibilityPreference(_ code: String, title: String) -> PendingEligibilityPreference {
        return PendingEligibilityPreference(
            code: code,
            title: title,
            phone: "",
            limit: 0,
            attributes: [:],
            status: PendingEligibilityPreferenceStatus.requested
        )
    }
}
