import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a global charge review must pass. Check returns its problems, or none.
    protocol GlobalChargeReviewRule {
        func check(_ item: GlobalChargeReview) -> [String]
    }

    final class GlobalChargeReviewCodePrefixRule: GlobalChargeReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalChargeReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalChargeReviewNameLengthRule: GlobalChargeReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalChargeReview) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalChargeReviewCodeLengthRule: GlobalChargeReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalChargeReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global charge review.
    final class GlobalChargeReviewValidator {
        var rules: [any GlobalChargeReviewRule]

        init(rules: [any GlobalChargeReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalChargeReview) -> [String] {
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

        func requireValid(_ item: GlobalChargeReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalChargeReview]) -> [String: [String]] {
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

    static func defaultGlobalChargeReviewValidator() -> GlobalChargeReviewValidator {
        return GlobalChargeReviewValidator(
            rules: [
                GlobalChargeReviewCodePrefixRule(prefix: "REF"),
                GlobalChargeReviewNameLengthRule(maxLength: 3600),
                GlobalChargeReviewCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
