import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered read target must pass. Check returns its problems, or none.
    protocol TieredReadTargetRule {
        func check(_ item: TieredReadTarget) -> [String]
    }

    final class TieredReadTargetRequiredFacilityRule: TieredReadTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredReadTarget) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredReadTargetRequiredTitleRule: TieredReadTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredReadTarget) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredReadTargetFacilityLengthRule: TieredReadTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReadTarget) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredReadTargetRequiredCodeRule: TieredReadTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredReadTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredReadTargetCategoryLengthRule: TieredReadTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReadTarget) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered read target.
    final class TieredReadTargetValidator {
        var rules: [any TieredReadTargetRule]

        init(rules: [any TieredReadTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredReadTarget) -> [String] {
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

        func requireValid(_ item: TieredReadTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredReadTarget]) -> [String: [String]] {
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

    static func defaultTieredReadTargetValidator() -> TieredReadTargetValidator {
        return TieredReadTargetValidator(
            rules: [
                TieredReadTargetRequiredFacilityRule(message: "tiered read target needs a value"),
                TieredReadTargetRequiredTitleRule(message: "tiered read target needs this field"),
                TieredReadTargetFacilityLengthRule(maxLength: 86400),
                TieredReadTargetRequiredCodeRule(message: "tiered read target needs an entry"),
                TieredReadTargetCategoryLengthRule(maxLength: 3600),
            ]
        )
    }
}
