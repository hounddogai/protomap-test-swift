import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality override must pass. Check returns its problems, or none.
    protocol ModalityOverrideRule {
        func check(_ item: ModalityOverride) -> [String]
    }

    final class ModalityOverrideAllowedCodeRule: ModalityOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ModalityOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class ModalityOverrideWindowDaysRangeRule: ModalityOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityOverride) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ModalityOverrideNameLengthRule: ModalityOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityOverride) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityOverrideCodePrefixRule: ModalityOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ModalityOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a modality override.
    final class ModalityOverrideValidator {
        var rules: [any ModalityOverrideRule]

        init(rules: [any ModalityOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ModalityOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityOverride]) -> [String: [String]] {
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

    static func defaultModalityOverrideValidator() -> ModalityOverrideValidator {
        return ModalityOverrideValidator(
            rules: [
                ModalityOverrideAllowedCodeRule(allowed: ["primary", "legacy"]),
                ModalityOverrideWindowDaysRangeRule(min: 16, max: 32),
                ModalityOverrideNameLengthRule(maxLength: 120),
                ModalityOverrideCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
