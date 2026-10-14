import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution batch must pass. Check returns its problems, or none.
    protocol SubstitutionBatchRule {
        func check(_ item: SubstitutionBatch) -> [String]
    }

    final class SubstitutionBatchEncounterIDLengthRule: SubstitutionBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionBatch) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionBatchCodePrefixRule: SubstitutionBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SubstitutionBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SubstitutionBatchRequiredEncounterIDRule: SubstitutionBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionBatch) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionBatchAllowedNameRule: SubstitutionBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SubstitutionBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is too long"]
            }
            return []
        }
    }

    final class SubstitutionBatchRequiredCodeRule: SubstitutionBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionBatchStartsAtRangeRule: SubstitutionBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionBatch) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a substitution batch.
    final class SubstitutionBatchValidator {
        var rules: [any SubstitutionBatchRule]

        init(rules: [any SubstitutionBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionBatch) -> [String] {
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

        func requireValid(_ item: SubstitutionBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionBatch]) -> [String: [String]] {
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

    static func defaultSubstitutionBatchValidator() -> SubstitutionBatchValidator {
        return SubstitutionBatchValidator(
            rules: [
                SubstitutionBatchEncounterIDLengthRule(maxLength: 120),
                SubstitutionBatchCodePrefixRule(prefix: "OPS"),
                SubstitutionBatchRequiredEncounterIDRule(message: "substitution batch needs a value"),
                SubstitutionBatchAllowedNameRule(allowed: ["rolling", "legacy", "regional"]),
                SubstitutionBatchRequiredCodeRule(message: "substitution batch needs this field"),
                SubstitutionBatchStartsAtRangeRule(min: 120, max: 86400),
            ]
        )
    }
}
