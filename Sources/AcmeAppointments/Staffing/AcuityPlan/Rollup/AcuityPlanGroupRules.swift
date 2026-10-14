import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan group must pass. Check returns its problems, or none.
    protocol AcuityPlanGroupRule {
        func check(_ item: AcuityPlanGroup) -> [String]
    }

    final class AcuityPlanGroupAllowedCodeRule: AcuityPlanGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AcuityPlanGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class AcuityPlanGroupStartsAtRangeRule: AcuityPlanGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanGroup) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AcuityPlanGroupCodePrefixRule: AcuityPlanGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AcuityPlanGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AcuityPlanGroupLabelLengthRule: AcuityPlanGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanGroup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanGroupRequiredCodeRule: AcuityPlanGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanGroupWindowDaysRangeRule: AcuityPlanGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanGroup) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan group.
    final class AcuityPlanGroupValidator {
        var rules: [any AcuityPlanGroupRule]

        init(rules: [any AcuityPlanGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AcuityPlanGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanGroup]) -> [String: [String]] {
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

    static func defaultAcuityPlanGroupValidator() -> AcuityPlanGroupValidator {
        return AcuityPlanGroupValidator(
            rules: [
                AcuityPlanGroupAllowedCodeRule(allowed: ["primary"]),
                AcuityPlanGroupStartsAtRangeRule(min: 120, max: 1000),
                AcuityPlanGroupCodePrefixRule(prefix: "ACM"),
                AcuityPlanGroupLabelLengthRule(maxLength: 3600),
                AcuityPlanGroupRequiredCodeRule(message: "acuity plan group needs this field"),
                AcuityPlanGroupWindowDaysRangeRule(min: 80, max: 1000),
            ]
        )
    }
}
