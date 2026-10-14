import AcmePlatform
import Foundation

extension Consent {
    /// Where a primary language profile is in its life cycle.
    enum PrimaryLanguageProfileStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a primary language profile and its current status.
    final class PrimaryLanguageProfile {
        var code: String
        var title: String
        var createdAt: Int
        var timezone: String
        var limit: Int
        var status: PrimaryLanguageProfileStatus

        init(code: String, title: String, createdAt: Int, timezone: String, limit: Int, status: PrimaryLanguageProfileStatus) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.timezone = timezone
            self.limit = limit
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

        func canMoveTo(_ next: PrimaryLanguageProfileStatus) -> Bool {
            switch status {
            case .created:
                return next == PrimaryLanguageProfileStatus.published || next == PrimaryLanguageProfileStatus.retired
            case .validated:
                return next == PrimaryLanguageProfileStatus.published || next == PrimaryLanguageProfileStatus.retired
            case .published:
                return next == PrimaryLanguageProfileStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryLanguageProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary language profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedValue() -> Double {
            return (Double(createdAt) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryLanguageProfile {
            return PrimaryLanguageProfile(
                code: code,
                title: title,
                createdAt: createdAt,
                timezone: timezone,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary language profile in status created.
    static func newPrimaryLanguageProfile(_ code: String, title: String) -> PrimaryLanguageProfile {
        return PrimaryLanguageProfile(
            code: code,
            title: title,
            createdAt: 0,
            timezone: "",
            limit: 0,
            status: PrimaryLanguageProfileStatus.created
        )
    }
}
