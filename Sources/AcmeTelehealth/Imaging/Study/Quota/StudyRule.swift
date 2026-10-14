import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study rule is in its life cycle.
    enum StudyRuleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A study rule as the study team keeps it.
    final class StudyRule {
        var code: String
        var name: String
        var attributes: [String: String]
        var tags: [String]
        var attempts: Int
        var version: Int
        var refills: Int
        var unit: String
        var batchSize: Int
        var rate: Double
        var status: StudyRuleStatus

        init(code: String, name: String, attributes: [String: String], tags: [String], attempts: Int, version: Int, refills: Int, unit: String, batchSize: Int, rate: Double, status: StudyRuleStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.tags = tags
            self.attempts = attempts
            self.version = version
            self.refills = refills
            self.unit = unit
            self.batchSize = batchSize
            self.rate = rate
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

        func canMoveTo(_ next: StudyRuleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == StudyRuleStatus.rejected || next == StudyRuleStatus.withdrawn
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

        func moveTo(_ next: StudyRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
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

        func weightedLoad() -> Double {
            return (Double(version) * rate * 100).rounded() / 100
        }

        func copyValue() -> StudyRule {
            return StudyRule(
                code: code,
                name: name,
                attributes: attributes,
                tags: tags,
                attempts: attempts,
                version: version,
                refills: refills,
                unit: unit,
                batchSize: batchSize,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a study rule in status proposed.
    static func newStudyRule(_ code: String, name: String) -> StudyRule {
        return StudyRule(
            code: code,
            name: name,
            attributes: [:],
            tags: [],
            attempts: 0,
            version: 0,
            refills: 0,
            unit: "",
            batchSize: 0,
            rate: 0.0,
            status: StudyRuleStatus.proposed
        )
    }
}
