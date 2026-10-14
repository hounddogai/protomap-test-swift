import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a adaptive network bundle must pass. Check returns its problems, or none.
    protocol AdaptiveNetworkBundleRule {
        func check(_ item: AdaptiveNetworkBundle) -> [String]
    }

    final class AdaptiveNetworkBundleDosageMgRangeRule: AdaptiveNetworkBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveNetworkBundle) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveNetworkBundleAllowedSummaryRule: AdaptiveNetworkBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveNetworkBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is blocked"]
            }
            return []
        }
    }

    final class AdaptiveNetworkBundleTitleLengthRule: AdaptiveNetworkBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveNetworkBundle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveNetworkBundleRequiredCodeRule: AdaptiveNetworkBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveNetworkBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveNetworkBundleReviewerLengthRule: AdaptiveNetworkBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveNetworkBundle) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive network bundle.
    final class AdaptiveNetworkBundleValidator {
        var rules: [any AdaptiveNetworkBundleRule]

        init(rules: [any AdaptiveNetworkBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveNetworkBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveNetworkBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveNetworkBundle]) -> [String: [String]] {
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

    static func defaultAdaptiveNetworkBundleValidator() -> AdaptiveNetworkBundleValidator {
        return AdaptiveNetworkBundleValidator(
            rules: [
                AdaptiveNetworkBundleDosageMgRangeRule(min: 5.5, max: 1078.4),
                AdaptiveNetworkBundleAllowedSummaryRule(allowed: []),
                AdaptiveNetworkBundleTitleLengthRule(maxLength: 32),
                AdaptiveNetworkBundleRequiredCodeRule(message: "adaptive network bundle needs this field"),
                AdaptiveNetworkBundleReviewerLengthRule(maxLength: 32),
            ]
        )
    }
}
