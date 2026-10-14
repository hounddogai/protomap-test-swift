import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a default claim bundle must pass. Check returns its problems, or none.
    protocol DefaultClaimBundleRule {
        func check(_ item: DefaultClaimBundle) -> [String]
    }

    final class DefaultClaimBundleTitleLengthRule: DefaultClaimBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultClaimBundle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultClaimBundlePinnedGuardRule: DefaultClaimBundleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: DefaultClaimBundle) -> [String] {
            if item.pinned && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class DefaultClaimBundleQuantityRangeRule: DefaultClaimBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultClaimBundle) -> [String] {
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

    /// Runs every rule of a default claim bundle.
    final class DefaultClaimBundleValidator {
        var rules: [any DefaultClaimBundleRule]

        init(rules: [any DefaultClaimBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultClaimBundle) -> [String] {
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

        func requireValid(_ item: DefaultClaimBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultClaimBundle]) -> [String: [String]] {
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

    static func defaultDefaultClaimBundleValidator() -> DefaultClaimBundleValidator {
        return DefaultClaimBundleValidator(
            rules: [
                DefaultClaimBundleTitleLengthRule(maxLength: 120),
                DefaultClaimBundlePinnedGuardRule(limit: 1000),
                DefaultClaimBundleQuantityRangeRule(min: 32, max: 80),
            ]
        )
    }
}
