import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a regional outreach mapping must pass. Check returns its problems, or none.
    protocol RegionalOutreachMappingRule {
        func check(_ item: RegionalOutreachMapping) -> [String]
    }

    final class RegionalOutreachMappingAllowedTitleRule: RegionalOutreachMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalOutreachMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is stale"]
            }
            return []
        }
    }

    final class RegionalOutreachMappingCodeLengthRule: RegionalOutreachMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalOutreachMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalOutreachMappingCodePrefixRule: RegionalOutreachMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalOutreachMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional outreach mapping.
    final class RegionalOutreachMappingValidator {
        var rules: [any RegionalOutreachMappingRule]

        init(rules: [any RegionalOutreachMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalOutreachMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalOutreachMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalOutreachMapping]) -> [String: [String]] {
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

    static func defaultRegionalOutreachMappingValidator() -> RegionalOutreachMappingValidator {
        return RegionalOutreachMappingValidator(
            rules: [
                RegionalOutreachMappingAllowedTitleRule(allowed: ["scheduled", "batched"]),
                RegionalOutreachMappingCodeLengthRule(maxLength: 255),
                RegionalOutreachMappingCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
