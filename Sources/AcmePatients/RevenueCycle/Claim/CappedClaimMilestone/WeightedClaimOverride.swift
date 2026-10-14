import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a weighted claim override is in its life cycle.
    enum WeightedClaimOverrideStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One weighted claim override, with what the planners need to act on it.
    final class WeightedClaimOverride {
        var code: String
        var name: String
        var tags: [String]
        var refills: Int
        var batchSize: Int
        var country: String
        var status: WeightedClaimOverrideStatus

        init(code: String, name: String, tags: [String], refills: Int, batchSize: Int, country: String, status: WeightedClaimOverrideStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.refills = refills
            self.batchSize = batchSize
            self.country = country
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedClaimOverrideStatus) -> Bool {
            switch status {
            case .`open`:
                return next == WeightedClaimOverrideStatus.inReview || next == WeightedClaimOverrideStatus.archived
            case .inReview:
                return next == WeightedClaimOverrideStatus.resolved
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: WeightedClaimOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted claim override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedTotal() -> Double {
            return ((Double(refills) + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedClaimOverride {
            return WeightedClaimOverride(
                code: code,
                name: name,
                tags: tags,
                refills: refills,
                batchSize: batchSize,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a weighted claim override in status open.
    static func newWeightedClaimOverride(_ code: String, name: String) -> WeightedClaimOverride {
        return WeightedClaimOverride(
            code: code,
            name: name,
            tags: [],
            refills: 0,
            batchSize: 0,
            country: "",
            status: WeightedClaimOverrideStatus.`open`
        )
    }
}
