import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a lenient program baseline must pass. Check returns its problems, or none.
    protocol LenientProgramBaselineRule {
        func check(_ item: LenientProgramBaseline) -> [String]
    }

    final class LenientProgramBaselineRequiredSpecialtyRule: LenientProgramBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientProgramBaseline) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientProgramBaselineRetriesRangeRule: LenientProgramBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientProgramBaseline) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientProgramBaselineCodeLengthRule: LenientProgramBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientProgramBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientProgramBaselineCodePrefixRule: LenientProgramBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientProgramBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientProgramBaselineRequiredLabelRule: LenientProgramBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientProgramBaseline) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientProgramBaselineAllowedCodeRule: LenientProgramBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientProgramBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient program baseline.
    final class LenientProgramBaselineValidator {
        var rules: [any LenientProgramBaselineRule]

        init(rules: [any LenientProgramBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientProgramBaseline) -> [String] {
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

        func requireValid(_ item: LenientProgramBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientProgramBaseline]) -> [String: [String]] {
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

    static func defaultLenientProgramBaselineValidator() -> LenientProgramBaselineValidator {
        return LenientProgramBaselineValidator(
            rules: [
                LenientProgramBaselineRequiredSpecialtyRule(message: "lenient program baseline needs a value"),
                LenientProgramBaselineRetriesRangeRule(min: 32, max: 1000),
                LenientProgramBaselineCodeLengthRule(maxLength: 86400),
                LenientProgramBaselineCodePrefixRule(prefix: "OPS"),
                LenientProgramBaselineRequiredLabelRule(message: "lenient program baseline needs this field"),
                LenientProgramBaselineAllowedCodeRule(allowed: []),
            ]
        )
    }
}
