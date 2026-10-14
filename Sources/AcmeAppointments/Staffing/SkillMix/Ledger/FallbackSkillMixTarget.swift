import AcmePlatform
import Foundation

extension Staffing {
    /// Where a fallback skill mix target is in its life cycle.
    enum FallbackSkillMixTargetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A fallback skill mix target as the skill mix team keeps it.
    final class FallbackSkillMixTarget {
        var code: String
        var title: String
        var refills: Int
        var tags: [String]
        var acuity: Int
        var maximum: Double
        var createdAt: Int
        var allergy: String
        var segment: String
        var source: String
        var status: FallbackSkillMixTargetStatus

        init(code: String, title: String, refills: Int, tags: [String], acuity: Int, maximum: Double, createdAt: Int, allergy: String, segment: String, source: String, status: FallbackSkillMixTargetStatus) {
            self.code = code
            self.title = title
            self.refills = refills
            self.tags = tags
            self.acuity = acuity
            self.maximum = maximum
            self.createdAt = createdAt
            self.allergy = allergy
            self.segment = segment
            self.source = source
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackSkillMixTargetStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: FallbackSkillMixTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback skill mix target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedLoad() -> Double {
            return (Double(createdAt) * maximum * 100).rounded() / 100
        }

        func copyValue() -> FallbackSkillMixTarget {
            return FallbackSkillMixTarget(
                code: code,
                title: title,
                refills: refills,
                tags: tags,
                acuity: acuity,
                maximum: maximum,
                createdAt: createdAt,
                allergy: allergy,
                segment: segment,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a fallback skill mix target in status proposed.
    static func newFallbackSkillMixTarget(_ code: String, title: String) -> FallbackSkillMixTarget {
        return FallbackSkillMixTarget(
            code: code,
            title: title,
            refills: 0,
            tags: [],
            acuity: 0,
            maximum: 0.0,
            createdAt: 0,
            allergy: "",
            segment: "",
            source: "",
            status: FallbackSkillMixTargetStatus.proposed
        )
    }
}
