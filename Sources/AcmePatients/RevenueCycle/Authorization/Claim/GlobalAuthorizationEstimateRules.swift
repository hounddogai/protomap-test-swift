import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a global authorization estimate must pass. Check returns its problems, or none.
    protocol GlobalAuthorizationEstimateRule {
        func check(_ item: GlobalAuthorizationEstimate) -> [String]
    }

    final class GlobalAuthorizationEstimateMinimumRangeRule: GlobalAuthorizationEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalAuthorizationEstimate) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalAuthorizationEstimateRegionLengthRule: GlobalAuthorizationEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalAuthorizationEstimate) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalAuthorizationEstimateCodeLengthRule: GlobalAuthorizationEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalAuthorizationEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global authorization estimate.
    final class GlobalAuthorizationEstimateValidator {
        var rules: [any GlobalAuthorizationEstimateRule]

        init(rules: [any GlobalAuthorizationEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalAuthorizationEstimate) -> [String] {
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

        func requireValid(_ item: GlobalAuthorizationEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalAuthorizationEstimate]) -> [String: [String]] {
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

    static func defaultGlobalAuthorizationEstimateValidator() -> GlobalAuthorizationEstimateValidator {
        return GlobalAuthorizationEstimateValidator(
            rules: [
                GlobalAuthorizationEstimateMinimumRangeRule(min: 0.7, max: 1978.3),
                GlobalAuthorizationEstimateRegionLengthRule(maxLength: 32),
                GlobalAuthorizationEstimateCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
