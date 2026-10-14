import AcmePlatform
import Foundation

extension Labs {
    /// A rule a primary accession window must pass. Check returns its problems, or none.
    protocol PrimaryAccessionWindowRule {
        func check(_ item: PrimaryAccessionWindow) -> [String]
    }

    final class PrimaryAccessionWindowCodePrefixRule: PrimaryAccessionWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryAccessionWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryAccessionWindowAllowedLabelRule: PrimaryAccessionWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryAccessionWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is out of range"]
            }
            return []
        }
    }

    final class PrimaryAccessionWindowCountryLengthRule: PrimaryAccessionWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryAccessionWindow) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryAccessionWindowPriorityRangeRule: PrimaryAccessionWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryAccessionWindow) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary accession window.
    final class PrimaryAccessionWindowValidator {
        var rules: [any PrimaryAccessionWindowRule]

        init(rules: [any PrimaryAccessionWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryAccessionWindow) -> [String] {
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

        func requireValid(_ item: PrimaryAccessionWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryAccessionWindow]) -> [String: [String]] {
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

    static func defaultPrimaryAccessionWindowValidator() -> PrimaryAccessionWindowValidator {
        return PrimaryAccessionWindowValidator(
            rules: [
                PrimaryAccessionWindowCodePrefixRule(prefix: "X"),
                PrimaryAccessionWindowAllowedLabelRule(allowed: ["pending", "lenient"]),
                PrimaryAccessionWindowCountryLengthRule(maxLength: 32),
                PrimaryAccessionWindowPriorityRangeRule(min: 80, max: 86400),
            ]
        )
    }
}
