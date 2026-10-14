import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a adaptive bed board target must pass. Check returns its problems, or none.
    protocol AdaptiveBedBoardTargetRule {
        func check(_ item: AdaptiveBedBoardTarget) -> [String]
    }

    final class AdaptiveBedBoardTargetCodePrefixRule: AdaptiveBedBoardTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveBedBoardTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveBedBoardTargetCategoryLengthRule: AdaptiveBedBoardTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveBedBoardTarget) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveBedBoardTargetCodeLengthRule: AdaptiveBedBoardTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveBedBoardTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive bed board target.
    final class AdaptiveBedBoardTargetValidator {
        var rules: [any AdaptiveBedBoardTargetRule]

        init(rules: [any AdaptiveBedBoardTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveBedBoardTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveBedBoardTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveBedBoardTarget]) -> [String: [String]] {
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

    static func defaultAdaptiveBedBoardTargetValidator() -> AdaptiveBedBoardTargetValidator {
        return AdaptiveBedBoardTargetValidator(
            rules: [
                AdaptiveBedBoardTargetCodePrefixRule(prefix: "Q"),
                AdaptiveBedBoardTargetCategoryLengthRule(maxLength: 64),
                AdaptiveBedBoardTargetCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
