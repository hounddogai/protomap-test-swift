import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a global isolation summary must pass. Check returns its problems, or none.
    protocol GlobalIsolationSummaryRule {
        func check(_ item: GlobalIsolationSummary) -> [String]
    }

    final class GlobalIsolationSummaryRequiredCodeRule: GlobalIsolationSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalIsolationSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalIsolationSummaryRequiredTitleRule: GlobalIsolationSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalIsolationSummary) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalIsolationSummaryCodePrefixRule: GlobalIsolationSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalIsolationSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalIsolationSummaryFacilityLengthRule: GlobalIsolationSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalIsolationSummary) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalIsolationSummaryRequiredFacilityRule: GlobalIsolationSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalIsolationSummary) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalIsolationSummaryAllowedTitleRule: GlobalIsolationSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalIsolationSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a global isolation summary.
    final class GlobalIsolationSummaryValidator {
        var rules: [any GlobalIsolationSummaryRule]

        init(rules: [any GlobalIsolationSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalIsolationSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalIsolationSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalIsolationSummary]) -> [String: [String]] {
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

    static func defaultGlobalIsolationSummaryValidator() -> GlobalIsolationSummaryValidator {
        return GlobalIsolationSummaryValidator(
            rules: [
                GlobalIsolationSummaryRequiredCodeRule(message: "global isolation summary needs this field"),
                GlobalIsolationSummaryRequiredTitleRule(message: "global isolation summary needs this field"),
                GlobalIsolationSummaryCodePrefixRule(prefix: "X"),
                GlobalIsolationSummaryFacilityLengthRule(maxLength: 16),
                GlobalIsolationSummaryRequiredFacilityRule(message: "global isolation summary needs this field"),
                GlobalIsolationSummaryAllowedTitleRule(allowed: ["adaptive", "primary", "regional"]),
            ]
        )
    }
}
