import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a adaptive shift baseline must pass. Check returns its problems, or none.
    protocol AdaptiveShiftBaselineRule {
        func check(_ item: AdaptiveShiftBaseline) -> [String]
    }

    final class AdaptiveShiftBaselineNameLengthRule: AdaptiveShiftBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveShiftBaseline) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveShiftBaselineCodePrefixRule: AdaptiveShiftBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveShiftBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveShiftBaselineRequiredNameRule: AdaptiveShiftBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveShiftBaseline) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveShiftBaselineRequiredCodeRule: AdaptiveShiftBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveShiftBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive shift baseline.
    final class AdaptiveShiftBaselineValidator {
        var rules: [any AdaptiveShiftBaselineRule]

        init(rules: [any AdaptiveShiftBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveShiftBaseline) -> [String] {
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

        func requireValid(_ item: AdaptiveShiftBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveShiftBaseline]) -> [String: [String]] {
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

    static func defaultAdaptiveShiftBaselineValidator() -> AdaptiveShiftBaselineValidator {
        return AdaptiveShiftBaselineValidator(
            rules: [
                AdaptiveShiftBaselineNameLengthRule(maxLength: 16),
                AdaptiveShiftBaselineCodePrefixRule(prefix: "X"),
                AdaptiveShiftBaselineRequiredNameRule(message: "adaptive shift baseline needs an entry"),
                AdaptiveShiftBaselineRequiredCodeRule(message: "adaptive shift baseline needs a value"),
            ]
        )
    }
}
