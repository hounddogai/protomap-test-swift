import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix claim is in its life cycle.
    enum SkillMixClaimStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A skill mix claim. Its code is unique within a tenant.
    final class SkillMixClaim {
        var code: String
        var title: String
        var region: String
        var tags: [String]
        var createdAt: Int
        var ownerID: String
        var checksum: String
        var status: SkillMixClaimStatus

        init(code: String, title: String, region: String, tags: [String], createdAt: Int, ownerID: String, checksum: String, status: SkillMixClaimStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.tags = tags
            self.createdAt = createdAt
            self.ownerID = ownerID
            self.checksum = checksum
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

        func canMoveTo(_ next: SkillMixClaimStatus) -> Bool {
            switch status {
            case .idle:
                return next == SkillMixClaimStatus.ready || next == SkillMixClaimStatus.stopped
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == SkillMixClaimStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SkillMixClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("skill mix claim") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(createdAt)
        }

        func copyValue() -> SkillMixClaim {
            return SkillMixClaim(
                code: code,
                title: title,
                region: region,
                tags: tags,
                createdAt: createdAt,
                ownerID: ownerID,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a skill mix claim in status idle.
    static func newSkillMixClaim(_ code: String, title: String) -> SkillMixClaim {
        return SkillMixClaim(
            code: code,
            title: title,
            region: "",
            tags: [],
            createdAt: 0,
            ownerID: "",
            checksum: "",
            status: SkillMixClaimStatus.idle
        )
    }
}
