import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a regional recall request must pass. Check returns its problems, or none.
    protocol RegionalRecallRequestRule {
        func check(_ item: RegionalRecallRequest) -> [String]
    }

    final class RegionalRecallRequestCodePrefixRule: RegionalRecallRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalRecallRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalRecallRequestAllowedTitleRule: RegionalRecallRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalRecallRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is expired"]
            }
            return []
        }
    }

    final class RegionalRecallRequestRequiredUnitRule: RegionalRecallRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalRecallRequest) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalRecallRequestRequiredTitleRule: RegionalRecallRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalRecallRequest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional recall request.
    final class RegionalRecallRequestValidator {
        var rules: [any RegionalRecallRequestRule]

        init(rules: [any RegionalRecallRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalRecallRequest) -> [String] {
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

        func requireValid(_ item: RegionalRecallRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalRecallRequest]) -> [String: [String]] {
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

    static func defaultRegionalRecallRequestValidator() -> RegionalRecallRequestValidator {
        return RegionalRecallRequestValidator(
            rules: [
                RegionalRecallRequestCodePrefixRule(prefix: "REF"),
                RegionalRecallRequestAllowedTitleRule(allowed: ["rolling", "capped"]),
                RegionalRecallRequestRequiredUnitRule(message: "regional recall request needs an entry"),
                RegionalRecallRequestRequiredTitleRule(message: "regional recall request needs this field"),
            ]
        )
    }
}
