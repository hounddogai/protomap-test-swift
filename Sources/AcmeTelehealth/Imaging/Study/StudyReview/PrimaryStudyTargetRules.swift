import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a primary study target must pass. Check returns its problems, or none.
    protocol PrimaryStudyTargetRule {
        func check(_ item: PrimaryStudyTarget) -> [String]
    }

    final class PrimaryStudyTargetRequiredCurrencyRule: PrimaryStudyTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryStudyTarget) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryStudyTargetRequiredCodeRule: PrimaryStudyTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryStudyTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryStudyTargetCodePrefixRule: PrimaryStudyTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryStudyTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryStudyTargetRequiredChecksumRule: PrimaryStudyTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryStudyTarget) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryStudyTargetCodeLengthRule: PrimaryStudyTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryStudyTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryStudyTargetAcuityRangeRule: PrimaryStudyTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryStudyTarget) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a primary study target.
    final class PrimaryStudyTargetValidator {
        var rules: [any PrimaryStudyTargetRule]

        init(rules: [any PrimaryStudyTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryStudyTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryStudyTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryStudyTarget]) -> [String: [String]] {
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

    static func defaultPrimaryStudyTargetValidator() -> PrimaryStudyTargetValidator {
        return PrimaryStudyTargetValidator(
            rules: [
                PrimaryStudyTargetRequiredCurrencyRule(message: "primary study target needs an entry"),
                PrimaryStudyTargetRequiredCodeRule(message: "primary study target needs an entry"),
                PrimaryStudyTargetCodePrefixRule(prefix: "OPS"),
                PrimaryStudyTargetRequiredChecksumRule(message: "primary study target needs this field"),
                PrimaryStudyTargetCodeLengthRule(maxLength: 1000),
                PrimaryStudyTargetAcuityRangeRule(min: 16, max: 1000),
            ]
        )
    }
}
