import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a regional isolation baseline must pass. Check returns its problems, or none.
    protocol RegionalIsolationBaselineRule {
        func check(_ item: RegionalIsolationBaseline) -> [String]
    }

    final class RegionalIsolationBaselineLocaleLengthRule: RegionalIsolationBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalIsolationBaseline) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalIsolationBaselineCodePrefixRule: RegionalIsolationBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalIsolationBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalIsolationBaselineTagsLimitRule: RegionalIsolationBaselineRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: RegionalIsolationBaseline) -> [String] {
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

    final class RegionalIsolationBaselineRequiredCodeRule: RegionalIsolationBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalIsolationBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional isolation baseline.
    final class RegionalIsolationBaselineValidator {
        var rules: [any RegionalIsolationBaselineRule]

        init(rules: [any RegionalIsolationBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalIsolationBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalIsolationBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalIsolationBaseline]) -> [String: [String]] {
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

    static func defaultRegionalIsolationBaselineValidator() -> RegionalIsolationBaselineValidator {
        return RegionalIsolationBaselineValidator(
            rules: [
                RegionalIsolationBaselineLocaleLengthRule(maxLength: 1000),
                RegionalIsolationBaselineCodePrefixRule(prefix: "REF"),
                RegionalIsolationBaselineTagsLimitRule(maxCount: 80, banned: ["lenient", "global", "adaptive"]),
                RegionalIsolationBaselineRequiredCodeRule(message: "regional isolation baseline needs an entry"),
            ]
        )
    }
}
