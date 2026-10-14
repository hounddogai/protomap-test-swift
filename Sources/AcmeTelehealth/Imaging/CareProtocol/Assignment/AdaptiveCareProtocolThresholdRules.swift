import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a adaptive care protocol threshold must pass. Check returns its problems, or none.
    protocol AdaptiveCareProtocolThresholdRule {
        func check(_ item: AdaptiveCareProtocolThreshold) -> [String]
    }

    final class AdaptiveCareProtocolThresholdTitleLengthRule: AdaptiveCareProtocolThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCareProtocolThreshold) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveCareProtocolThresholdCodePrefixRule: AdaptiveCareProtocolThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveCareProtocolThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveCareProtocolThresholdCategoryLengthRule: AdaptiveCareProtocolThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCareProtocolThreshold) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive care protocol threshold.
    final class AdaptiveCareProtocolThresholdValidator {
        var rules: [any AdaptiveCareProtocolThresholdRule]

        init(rules: [any AdaptiveCareProtocolThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveCareProtocolThreshold) -> [String] {
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

        func requireValid(_ item: AdaptiveCareProtocolThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveCareProtocolThreshold]) -> [String: [String]] {
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

    static func defaultAdaptiveCareProtocolThresholdValidator() -> AdaptiveCareProtocolThresholdValidator {
        return AdaptiveCareProtocolThresholdValidator(
            rules: [
                AdaptiveCareProtocolThresholdTitleLengthRule(maxLength: 32),
                AdaptiveCareProtocolThresholdCodePrefixRule(prefix: "ACM"),
                AdaptiveCareProtocolThresholdCategoryLengthRule(maxLength: 32),
            ]
        )
    }
}
