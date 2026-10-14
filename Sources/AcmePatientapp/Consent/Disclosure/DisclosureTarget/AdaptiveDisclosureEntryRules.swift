import AcmePlatform
import Foundation

extension Consent {
    /// A rule a adaptive disclosure entry must pass. Check returns its problems, or none.
    protocol AdaptiveDisclosureEntryRule {
        func check(_ item: AdaptiveDisclosureEntry) -> [String]
    }

    final class AdaptiveDisclosureEntryCodePrefixRule: AdaptiveDisclosureEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveDisclosureEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveDisclosureEntryCodeLengthRule: AdaptiveDisclosureEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveDisclosureEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveDisclosureEntryRequiredNameRule: AdaptiveDisclosureEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveDisclosureEntry) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveDisclosureEntryDiscountRangeRule: AdaptiveDisclosureEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveDisclosureEntry) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveDisclosureEntryNameLengthRule: AdaptiveDisclosureEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveDisclosureEntry) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive disclosure entry.
    final class AdaptiveDisclosureEntryValidator {
        var rules: [any AdaptiveDisclosureEntryRule]

        init(rules: [any AdaptiveDisclosureEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveDisclosureEntry) -> [String] {
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

        func requireValid(_ item: AdaptiveDisclosureEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveDisclosureEntry]) -> [String: [String]] {
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

    static func defaultAdaptiveDisclosureEntryValidator() -> AdaptiveDisclosureEntryValidator {
        return AdaptiveDisclosureEntryValidator(
            rules: [
                AdaptiveDisclosureEntryCodePrefixRule(prefix: "OPS"),
                AdaptiveDisclosureEntryCodeLengthRule(maxLength: 80),
                AdaptiveDisclosureEntryRequiredNameRule(message: "adaptive disclosure entry needs this field"),
                AdaptiveDisclosureEntryDiscountRangeRule(min: 8.5, max: 2324.2),
                AdaptiveDisclosureEntryNameLengthRule(maxLength: 32),
            ]
        )
    }
}
