import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a rolling float pool estimate must pass. Check returns its problems, or none.
    protocol RollingFloatPoolEstimateRule {
        func check(_ item: RollingFloatPoolEstimate) -> [String]
    }

    final class RollingFloatPoolEstimateNameLengthRule: RollingFloatPoolEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingFloatPoolEstimate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingFloatPoolEstimateRequiredCountryRule: RollingFloatPoolEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingFloatPoolEstimate) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingFloatPoolEstimateSegmentLengthRule: RollingFloatPoolEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingFloatPoolEstimate) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingFloatPoolEstimateCodeLengthRule: RollingFloatPoolEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingFloatPoolEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling float pool estimate.
    final class RollingFloatPoolEstimateValidator {
        var rules: [any RollingFloatPoolEstimateRule]

        init(rules: [any RollingFloatPoolEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingFloatPoolEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingFloatPoolEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingFloatPoolEstimate]) -> [String: [String]] {
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

    static func defaultRollingFloatPoolEstimateValidator() -> RollingFloatPoolEstimateValidator {
        return RollingFloatPoolEstimateValidator(
            rules: [
                RollingFloatPoolEstimateNameLengthRule(maxLength: 64),
                RollingFloatPoolEstimateRequiredCountryRule(message: "rolling float pool estimate needs this field"),
                RollingFloatPoolEstimateSegmentLengthRule(maxLength: 80),
                RollingFloatPoolEstimateCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
