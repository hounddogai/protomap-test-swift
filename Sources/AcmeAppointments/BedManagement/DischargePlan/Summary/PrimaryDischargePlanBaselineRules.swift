import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a primary discharge plan baseline must pass. Check returns its problems, or none.
    protocol PrimaryDischargePlanBaselineRule {
        func check(_ item: PrimaryDischargePlanBaseline) -> [String]
    }

    final class PrimaryDischargePlanBaselineNameLengthRule: PrimaryDischargePlanBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryDischargePlanBaseline) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryDischargePlanBaselineTitleLengthRule: PrimaryDischargePlanBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryDischargePlanBaseline) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryDischargePlanBaselineCodePrefixRule: PrimaryDischargePlanBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryDischargePlanBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryDischargePlanBaselineQuantityRangeRule: PrimaryDischargePlanBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryDischargePlanBaseline) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryDischargePlanBaselineRequiredPhoneRule: PrimaryDischargePlanBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryDischargePlanBaseline) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryDischargePlanBaselineRequiredNameRule: PrimaryDischargePlanBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryDischargePlanBaseline) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary discharge plan baseline.
    final class PrimaryDischargePlanBaselineValidator {
        var rules: [any PrimaryDischargePlanBaselineRule]

        init(rules: [any PrimaryDischargePlanBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryDischargePlanBaseline) -> [String] {
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

        func requireValid(_ item: PrimaryDischargePlanBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryDischargePlanBaseline]) -> [String: [String]] {
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

    static func defaultPrimaryDischargePlanBaselineValidator() -> PrimaryDischargePlanBaselineValidator {
        return PrimaryDischargePlanBaselineValidator(
            rules: [
                PrimaryDischargePlanBaselineNameLengthRule(maxLength: 64),
                PrimaryDischargePlanBaselineTitleLengthRule(maxLength: 80),
                PrimaryDischargePlanBaselineCodePrefixRule(prefix: "X"),
                PrimaryDischargePlanBaselineQuantityRangeRule(min: 120, max: 86400),
                PrimaryDischargePlanBaselineRequiredPhoneRule(
                    message: "primary discharge plan baseline needs a value"
                ),
                PrimaryDischargePlanBaselineRequiredNameRule(message: "primary discharge plan baseline needs a value"),
            ]
        )
    }
}
