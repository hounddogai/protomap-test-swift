import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a default claim rollup is in its life cycle.
    enum DefaultClaimRollupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A default claim rollup. Its code is unique within a tenant.
    final class DefaultClaimRollup {
        var code: String
        var name: String
        var ceiling: Double
        var title: String
        var tags: [String]
        var revision: Int
        var batchSize: Int
        var windowDays: Int
        var category: String
        var status: DefaultClaimRollupStatus

        init(code: String, name: String, ceiling: Double, title: String, tags: [String], revision: Int, batchSize: Int, windowDays: Int, category: String, status: DefaultClaimRollupStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.title = title
            self.tags = tags
            self.revision = revision
            self.batchSize = batchSize
            self.windowDays = windowDays
            self.category = category
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

        func canMoveTo(_ next: DefaultClaimRollupStatus) -> Bool {
            switch status {
            case .requested:
                return next == DefaultClaimRollupStatus.revoked
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: DefaultClaimRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default claim rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("default claim rollup") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveLoad() -> Double {
            return ((ceiling + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultClaimRollup {
            return DefaultClaimRollup(
                code: code,
                name: name,
                ceiling: ceiling,
                title: title,
                tags: tags,
                revision: revision,
                batchSize: batchSize,
                windowDays: windowDays,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a default claim rollup in status requested.
    static func newDefaultClaimRollup(_ code: String, name: String) -> DefaultClaimRollup {
        return DefaultClaimRollup(
            code: code,
            name: name,
            ceiling: 0.0,
            title: "",
            tags: [],
            revision: 0,
            batchSize: 0,
            windowDays: 0,
            category: "",
            status: DefaultClaimRollupStatus.requested
        )
    }
}
