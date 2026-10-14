import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census group must pass. Check returns its problems, or none.
    protocol CensusGroupRule {
        func check(_ item: CensusGroup) -> [String]
    }

    final class CensusGroupVersionRangeRule: CensusGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusGroup) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CensusGroupRequiredCodeRule: CensusGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusGroupLabelLengthRule: CensusGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusGroup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusGroupTitleLengthRule: CensusGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusGroup) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusGroupRequiredTitleRule: CensusGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusGroup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusGroupAllowedBedRule: CensusGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CensusGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.bed)) {
                return ["bed \(item.bed) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a census group.
    final class CensusGroupValidator {
        var rules: [any CensusGroupRule]

        init(rules: [any CensusGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusGroup) -> [String] {
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

        func requireValid(_ item: CensusGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusGroup]) -> [String: [String]] {
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

    static func defaultCensusGroupValidator() -> CensusGroupValidator {
        return CensusGroupValidator(
            rules: [
                CensusGroupVersionRangeRule(min: 16, max: 16),
                CensusGroupRequiredCodeRule(message: "census group needs a value"),
                CensusGroupLabelLengthRule(maxLength: 1000),
                CensusGroupTitleLengthRule(maxLength: 32),
                CensusGroupRequiredTitleRule(message: "census group needs a value"),
                CensusGroupAllowedBedRule(allowed: ["batched", "rolling", "global"]),
            ]
        )
    }
}
