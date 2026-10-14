import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix mapping is in its life cycle.
    enum SkillMixMappingStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a skill mix mapping and its current status.
    final class SkillMixMapping {
        var code: String
        var label: String
        var tags: [String]
        var ward: String
        var visible: Bool
        var attributes: [String: String]
        var score: Double
        var status: SkillMixMappingStatus

        init(code: String, label: String, tags: [String], ward: String, visible: Bool, attributes: [String: String], score: Double, status: SkillMixMappingStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.ward = ward
            self.visible = visible
            self.attributes = attributes
            self.score = score
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

        func canMoveTo(_ next: SkillMixMappingStatus) -> Bool {
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
                return next == SkillMixMappingStatus.retired
            case .published:
                return next == SkillMixMappingStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SkillMixMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("skill mix mapping") \(code)"
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

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> SkillMixMapping {
            return SkillMixMapping(
                code: code,
                label: label,
                tags: tags,
                ward: ward,
                visible: visible,
                attributes: attributes,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a skill mix mapping in status created.
    static func newSkillMixMapping(_ code: String, label: String) -> SkillMixMapping {
        return SkillMixMapping(
            code: code,
            label: label,
            tags: [],
            ward: "",
            visible: false,
            attributes: [:],
            score: 0.0,
            status: SkillMixMappingStatus.created
        )
    }
}
