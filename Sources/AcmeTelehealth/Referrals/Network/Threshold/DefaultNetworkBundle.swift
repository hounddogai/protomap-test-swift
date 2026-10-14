import AcmePlatform
import Foundation

extension Referrals {
    /// Where a default network bundle is in its life cycle.
    enum DefaultNetworkBundleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a default network bundle and its current status.
    final class DefaultNetworkBundle {
        var code: String
        var title: String
        var category: String
        var minimum: Double
        var source: String
        var limit: Int
        var timezone: String
        var reviewer: String
        var weight: Double
        var retries: Int
        var status: DefaultNetworkBundleStatus

        init(code: String, title: String, category: String, minimum: Double, source: String, limit: Int, timezone: String, reviewer: String, weight: Double, retries: Int, status: DefaultNetworkBundleStatus) {
            self.code = code
            self.title = title
            self.category = category
            self.minimum = minimum
            self.source = source
            self.limit = limit
            self.timezone = timezone
            self.reviewer = reviewer
            self.weight = weight
            self.retries = retries
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

        func canMoveTo(_ next: DefaultNetworkBundleStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: DefaultNetworkBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default network bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("default network bundle") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((weight + minimum) * 100).rounded() / 100
        }

        func copyValue() -> DefaultNetworkBundle {
            return DefaultNetworkBundle(
                code: code,
                title: title,
                category: category,
                minimum: minimum,
                source: source,
                limit: limit,
                timezone: timezone,
                reviewer: reviewer,
                weight: weight,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a default network bundle in status created.
    static func newDefaultNetworkBundle(_ code: String, title: String) -> DefaultNetworkBundle {
        return DefaultNetworkBundle(
            code: code,
            title: title,
            category: "",
            minimum: 0.0,
            source: "",
            limit: 0,
            timezone: "",
            reviewer: "",
            weight: 0.0,
            retries: 0,
            status: DefaultNetworkBundleStatus.created
        )
    }
}
