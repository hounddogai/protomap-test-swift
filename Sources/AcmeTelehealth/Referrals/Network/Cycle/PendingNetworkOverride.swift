import AcmePlatform
import Foundation

extension Referrals {
    /// Where a pending network override is in its life cycle.
    enum PendingNetworkOverrideStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A pending network override as the network team keeps it.
    final class PendingNetworkOverride {
        var code: String
        var name: String
        var priority: Int
        var region: String
        var maximum: Double
        var pinned: Bool
        var clinicianID: String
        var reviewer: String
        var tags: [String]
        var limit: Int
        var status: PendingNetworkOverrideStatus

        init(code: String, name: String, priority: Int, region: String, maximum: Double, pinned: Bool, clinicianID: String, reviewer: String, tags: [String], limit: Int, status: PendingNetworkOverrideStatus) {
            self.code = code
            self.name = name
            self.priority = priority
            self.region = region
            self.maximum = maximum
            self.pinned = pinned
            self.clinicianID = clinicianID
            self.reviewer = reviewer
            self.tags = tags
            self.limit = limit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingNetworkOverrideStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == PendingNetworkOverrideStatus.running
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: PendingNetworkOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending network override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedVolume() -> Double {
            return ((Double(limit) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> PendingNetworkOverride {
            return PendingNetworkOverride(
                code: code,
                name: name,
                priority: priority,
                region: region,
                maximum: maximum,
                pinned: pinned,
                clinicianID: clinicianID,
                reviewer: reviewer,
                tags: tags,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a pending network override in status new.
    static func newPendingNetworkOverride(_ code: String, name: String) -> PendingNetworkOverride {
        return PendingNetworkOverride(
            code: code,
            name: name,
            priority: 0,
            region: "",
            maximum: 0.0,
            pinned: false,
            clinicianID: "",
            reviewer: "",
            tags: [],
            limit: 0,
            status: PendingNetworkOverrideStatus.new
        )
    }
}
