import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a adaptive outreach tier is in its life cycle.
    enum AdaptiveOutreachTierStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One adaptive outreach tier, with what the planners need to act on it.
    final class AdaptiveOutreachTier {
        var code: String
        var title: String
        var region: String
        var priority: Int
        var description: String
        var pinned: Bool
        var startsAt: Int
        var attributes: [String: String]
        var cost: Double
        var status: AdaptiveOutreachTierStatus

        init(code: String, title: String, region: String, priority: Int, description: String, pinned: Bool, startsAt: Int, attributes: [String: String], cost: Double, status: AdaptiveOutreachTierStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.priority = priority
            self.description = description
            self.pinned = pinned
            self.startsAt = startsAt
            self.attributes = attributes
            self.cost = cost
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

        func canMoveTo(_ next: AdaptiveOutreachTierStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == AdaptiveOutreachTierStatus.draining || next == AdaptiveOutreachTierStatus.stopped
            case .ready:
                return next == AdaptiveOutreachTierStatus.stopped
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

        func moveTo(_ next: AdaptiveOutreachTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive outreach tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
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

        func weightedLoad() -> Double {
            return ((Double(priority) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveOutreachTier {
            return AdaptiveOutreachTier(
                code: code,
                title: title,
                region: region,
                priority: priority,
                description: description,
                pinned: pinned,
                startsAt: startsAt,
                attributes: attributes,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a adaptive outreach tier in status idle.
    static func newAdaptiveOutreachTier(_ code: String, title: String) -> AdaptiveOutreachTier {
        return AdaptiveOutreachTier(
            code: code,
            title: title,
            region: "",
            priority: 0,
            description: "",
            pinned: false,
            startsAt: 0,
            attributes: [:],
            cost: 0.0,
            status: AdaptiveOutreachTierStatus.idle
        )
    }
}
