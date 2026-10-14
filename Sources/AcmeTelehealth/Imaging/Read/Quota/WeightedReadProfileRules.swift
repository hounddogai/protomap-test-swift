import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a weighted read profile must pass. Check returns its problems, or none.
    protocol WeightedReadProfileRule {
        func check(_ item: WeightedReadProfile) -> [String]
    }

    final class WeightedReadProfileCodeLengthRule: WeightedReadProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedReadProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedReadProfileRequiredNameRule: WeightedReadProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedReadProfile) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedReadProfileExternalRefLengthRule: WeightedReadProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedReadProfile) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedReadProfileRequiredCodeRule: WeightedReadProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedReadProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedReadProfileCategoryLengthRule: WeightedReadProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedReadProfile) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedReadProfileCodePrefixRule: WeightedReadProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedReadProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted read profile.
    final class WeightedReadProfileValidator {
        var rules: [any WeightedReadProfileRule]

        init(rules: [any WeightedReadProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedReadProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedReadProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedReadProfile]) -> [String: [String]] {
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

    static func defaultWeightedReadProfileValidator() -> WeightedReadProfileValidator {
        return WeightedReadProfileValidator(
            rules: [
                WeightedReadProfileCodeLengthRule(maxLength: 86400),
                WeightedReadProfileRequiredNameRule(message: "weighted read profile needs an entry"),
                WeightedReadProfileExternalRefLengthRule(maxLength: 1000),
                WeightedReadProfileRequiredCodeRule(message: "weighted read profile needs an entry"),
                WeightedReadProfileCategoryLengthRule(maxLength: 32),
                WeightedReadProfileCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
