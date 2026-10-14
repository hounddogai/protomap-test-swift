import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a tiered authorization bundle is in its life cycle.
    enum TieredAuthorizationBundleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A tiered authorization bundle. Its code is unique within a tenant.
    final class TieredAuthorizationBundle {
        var code: String
        var title: String
        var budget: Double
        var durationMinutes: Int
        var approved: Bool
        var createdAt: Int
        var timezone: String
        var checksum: String
        var status: TieredAuthorizationBundleStatus

        init(code: String, title: String, budget: Double, durationMinutes: Int, approved: Bool, createdAt: Int, timezone: String, checksum: String, status: TieredAuthorizationBundleStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.durationMinutes = durationMinutes
            self.approved = approved
            self.createdAt = createdAt
            self.timezone = timezone
            self.checksum = checksum
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

        func canMoveTo(_ next: TieredAuthorizationBundleStatus) -> Bool {
            switch status {
            case .draft:
                return next == TieredAuthorizationBundleStatus.closed
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
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

        func moveTo(_ next: TieredAuthorizationBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered authorization bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("tiered authorization bundle") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(durationMinutes) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> TieredAuthorizationBundle {
            return TieredAuthorizationBundle(
                code: code,
                title: title,
                budget: budget,
                durationMinutes: durationMinutes,
                approved: approved,
                createdAt: createdAt,
                timezone: timezone,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered authorization bundle in status draft.
    static func newTieredAuthorizationBundle(_ code: String, title: String) -> TieredAuthorizationBundle {
        return TieredAuthorizationBundle(
            code: code,
            title: title,
            budget: 0.0,
            durationMinutes: 0,
            approved: false,
            createdAt: 0,
            timezone: "",
            checksum: "",
            status: TieredAuthorizationBundleStatus.draft
        )
    }
}
