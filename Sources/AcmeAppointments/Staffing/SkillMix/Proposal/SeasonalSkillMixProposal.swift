import AcmePlatform
import Foundation

extension Staffing {
    /// Where a seasonal skill mix proposal is in its life cycle.
    enum SeasonalSkillMixProposalStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A seasonal skill mix proposal as the skill mix team keeps it.
    final class SeasonalSkillMixProposal {
        var code: String
        var name: String
        var summary: String
        var tags: [String]
        var region: String
        var refills: Int
        var ratio: Double
        var budget: Double
        var attributes: [String: String]
        var capacity: Int
        var status: SeasonalSkillMixProposalStatus

        init(code: String, name: String, summary: String, tags: [String], region: String, refills: Int, ratio: Double, budget: Double, attributes: [String: String], capacity: Int, status: SeasonalSkillMixProposalStatus) {
            self.code = code
            self.name = name
            self.summary = summary
            self.tags = tags
            self.region = region
            self.refills = refills
            self.ratio = ratio
            self.budget = budget
            self.attributes = attributes
            self.capacity = capacity
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

        func canMoveTo(_ next: SeasonalSkillMixProposalStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == SeasonalSkillMixProposalStatus.rejected
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

        func moveTo(_ next: SeasonalSkillMixProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal skill mix proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
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

        func adjustedValue() -> Double {
            return (Double(capacity) * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalSkillMixProposal {
            return SeasonalSkillMixProposal(
                code: code,
                name: name,
                summary: summary,
                tags: tags,
                region: region,
                refills: refills,
                ratio: ratio,
                budget: budget,
                attributes: attributes,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a seasonal skill mix proposal in status proposed.
    static func newSeasonalSkillMixProposal(_ code: String, name: String) -> SeasonalSkillMixProposal {
        return SeasonalSkillMixProposal(
            code: code,
            name: name,
            summary: "",
            tags: [],
            region: "",
            refills: 0,
            ratio: 0.0,
            budget: 0.0,
            attributes: [:],
            capacity: 0,
            status: SeasonalSkillMixProposalStatus.proposed
        )
    }
}
