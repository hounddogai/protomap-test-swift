import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered read group must pass. Check returns its problems, or none.
    protocol TieredReadGroupRule {
        func check(_ item: TieredReadGroup) -> [String]
    }

    final class TieredReadGroupStartsAtRangeRule: TieredReadGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredReadGroup) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredReadGroupRequiredRegionRule: TieredReadGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredReadGroup) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredReadGroupRegionLengthRule: TieredReadGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReadGroup) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredReadGroupNameLengthRule: TieredReadGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReadGroup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredReadGroupCodePrefixRule: TieredReadGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredReadGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredReadGroupRequiredAllergyRule: TieredReadGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredReadGroup) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered read group.
    final class TieredReadGroupValidator {
        var rules: [any TieredReadGroupRule]

        init(rules: [any TieredReadGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredReadGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredReadGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredReadGroup]) -> [String: [String]] {
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

    static func defaultTieredReadGroupValidator() -> TieredReadGroupValidator {
        return TieredReadGroupValidator(
            rules: [
                TieredReadGroupStartsAtRangeRule(min: 80, max: 120),
                TieredReadGroupRequiredRegionRule(message: "tiered read group needs an entry"),
                TieredReadGroupRegionLengthRule(maxLength: 80),
                TieredReadGroupNameLengthRule(maxLength: 255),
                TieredReadGroupCodePrefixRule(prefix: "REF"),
                TieredReadGroupRequiredAllergyRule(message: "tiered read group needs a value"),
            ]
        )
    }
}
