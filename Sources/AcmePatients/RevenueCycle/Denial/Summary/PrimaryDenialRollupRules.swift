import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a primary denial rollup must pass. Check returns its problems, or none.
    protocol PrimaryDenialRollupRule {
        func check(_ item: PrimaryDenialRollup) -> [String]
    }

    final class PrimaryDenialRollupCodeLengthRule: PrimaryDenialRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryDenialRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryDenialRollupLimitRangeRule: PrimaryDenialRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryDenialRollup) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryDenialRollupRequiredTitleRule: PrimaryDenialRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryDenialRollup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryDenialRollupRequiredCodeRule: PrimaryDenialRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryDenialRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryDenialRollupPhoneLengthRule: PrimaryDenialRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryDenialRollup) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryDenialRollupRequiredPhoneRule: PrimaryDenialRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryDenialRollup) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary denial rollup.
    final class PrimaryDenialRollupValidator {
        var rules: [any PrimaryDenialRollupRule]

        init(rules: [any PrimaryDenialRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryDenialRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryDenialRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryDenialRollup]) -> [String: [String]] {
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

    static func defaultPrimaryDenialRollupValidator() -> PrimaryDenialRollupValidator {
        return PrimaryDenialRollupValidator(
            rules: [
                PrimaryDenialRollupCodeLengthRule(maxLength: 86400),
                PrimaryDenialRollupLimitRangeRule(min: 255, max: 3600),
                PrimaryDenialRollupRequiredTitleRule(message: "primary denial rollup needs an entry"),
                PrimaryDenialRollupRequiredCodeRule(message: "primary denial rollup needs an entry"),
                PrimaryDenialRollupPhoneLengthRule(maxLength: 1000),
                PrimaryDenialRollupRequiredPhoneRule(message: "primary denial rollup needs a value"),
            ]
        )
    }
}
