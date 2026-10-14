import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a seasonal substitution quota is in its life cycle.
    enum SeasonalSubstitutionQuotaStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A seasonal substitution quota. Its code is unique within a tenant.
    final class SeasonalSubstitutionQuota {
        var code: String
        var title: String
        var capacity: Int
        var version: Int
        var approved: Bool
        var durationMinutes: Int
        var score: Double
        var expiresAt: Int
        var status: SeasonalSubstitutionQuotaStatus

        init(code: String, title: String, capacity: Int, version: Int, approved: Bool, durationMinutes: Int, score: Double, expiresAt: Int, status: SeasonalSubstitutionQuotaStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.version = version
            self.approved = approved
            self.durationMinutes = durationMinutes
            self.score = score
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: SeasonalSubstitutionQuotaStatus) -> Bool {
            switch status {
            case .draft:
                return next == SeasonalSubstitutionQuotaStatus.suspended
            case .pending:
                return next == SeasonalSubstitutionQuotaStatus.active || next == SeasonalSubstitutionQuotaStatus.suspended
            case .active:
                return next == SeasonalSubstitutionQuotaStatus.suspended || next == SeasonalSubstitutionQuotaStatus.closed
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

        func moveTo(_ next: SeasonalSubstitutionQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal substitution quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveValue() -> Double {
            return ((Double(capacity) - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalSubstitutionQuota {
            return SeasonalSubstitutionQuota(
                code: code,
                title: title,
                capacity: capacity,
                version: version,
                approved: approved,
                durationMinutes: durationMinutes,
                score: score,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal substitution quota in status draft.
    static func newSeasonalSubstitutionQuota(_ code: String, title: String) -> SeasonalSubstitutionQuota {
        return SeasonalSubstitutionQuota(
            code: code,
            title: title,
            capacity: 0,
            version: 0,
            approved: false,
            durationMinutes: 0,
            score: 0.0,
            expiresAt: 0,
            status: SeasonalSubstitutionQuotaStatus.draft
        )
    }
}
