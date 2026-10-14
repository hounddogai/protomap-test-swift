import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a regional isolation plan is in its life cycle.
    enum RegionalIsolationPlanStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A regional isolation plan as the isolation team keeps it.
    final class RegionalIsolationPlan {
        var code: String
        var title: String
        var windowDays: Int
        var endsAt: Int
        var expiresAt: Int
        var createdAt: Int
        var limit: Int
        var region: String
        var status: RegionalIsolationPlanStatus

        init(code: String, title: String, windowDays: Int, endsAt: Int, expiresAt: Int, createdAt: Int, limit: Int, region: String, status: RegionalIsolationPlanStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.endsAt = endsAt
            self.expiresAt = expiresAt
            self.createdAt = createdAt
            self.limit = limit
            self.region = region
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalIsolationPlanStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == RegionalIsolationPlanStatus.draining
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: RegionalIsolationPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional isolation plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedTotal() -> Double {
            return ((Double(endsAt) - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalIsolationPlan {
            return RegionalIsolationPlan(
                code: code,
                title: title,
                windowDays: windowDays,
                endsAt: endsAt,
                expiresAt: expiresAt,
                createdAt: createdAt,
                limit: limit,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a regional isolation plan in status idle.
    static func newRegionalIsolationPlan(_ code: String, title: String) -> RegionalIsolationPlan {
        return RegionalIsolationPlan(
            code: code,
            title: title,
            windowDays: 0,
            endsAt: 0,
            expiresAt: 0,
            createdAt: 0,
            limit: 0,
            region: "",
            status: RegionalIsolationPlanStatus.idle
        )
    }
}
