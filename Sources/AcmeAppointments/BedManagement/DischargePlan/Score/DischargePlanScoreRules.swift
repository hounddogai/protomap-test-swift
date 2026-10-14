import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan score must pass. Check returns its problems, or none.
    protocol DischargePlanScoreRule {
        func check(_ item: DischargePlanScore) -> [String]
    }

    final class DischargePlanScoreRequiredNameRule: DischargePlanScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanScore) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanScoreTagsLimitRule: DischargePlanScoreRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: DischargePlanScore) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class DischargePlanScoreRequiredSegmentRule: DischargePlanScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanScore) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanScoreClinicianIDLengthRule: DischargePlanScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanScore) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanScoreCapacityRangeRule: DischargePlanScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanScore) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DischargePlanScoreRequiredClinicianIDRule: DischargePlanScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanScore) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan score.
    final class DischargePlanScoreValidator {
        var rules: [any DischargePlanScoreRule]

        init(rules: [any DischargePlanScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: DischargePlanScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanScore]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultDischargePlanScoreValidator() -> DischargePlanScoreValidator {
        return DischargePlanScoreValidator(
            rules: [
                DischargePlanScoreRequiredNameRule(message: "discharge plan score needs this field"),
                DischargePlanScoreTagsLimitRule(maxCount: 32, banned: ["primary"]),
                DischargePlanScoreRequiredSegmentRule(message: "discharge plan score needs an entry"),
                DischargePlanScoreClinicianIDLengthRule(maxLength: 1000),
                DischargePlanScoreCapacityRangeRule(min: 16, max: 1000),
                DischargePlanScoreRequiredClinicianIDRule(message: "discharge plan score needs this field"),
            ]
        )
    }
}
