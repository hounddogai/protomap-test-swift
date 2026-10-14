import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a regional float pool override must pass. Check returns its problems, or none.
    protocol RegionalFloatPoolOverrideRule {
        func check(_ item: RegionalFloatPoolOverride) -> [String]
    }

    final class RegionalFloatPoolOverrideTitleLengthRule: RegionalFloatPoolOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalFloatPoolOverride) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalFloatPoolOverrideCodeLengthRule: RegionalFloatPoolOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalFloatPoolOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalFloatPoolOverrideCodePrefixRule: RegionalFloatPoolOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalFloatPoolOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional float pool override.
    final class RegionalFloatPoolOverrideValidator {
        var rules: [any RegionalFloatPoolOverrideRule]

        init(rules: [any RegionalFloatPoolOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalFloatPoolOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalFloatPoolOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalFloatPoolOverride]) -> [String: [String]] {
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

    static func defaultRegionalFloatPoolOverrideValidator() -> RegionalFloatPoolOverrideValidator {
        return RegionalFloatPoolOverrideValidator(
            rules: [
                RegionalFloatPoolOverrideTitleLengthRule(maxLength: 1000),
                RegionalFloatPoolOverrideCodeLengthRule(maxLength: 86400),
                RegionalFloatPoolOverrideCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
