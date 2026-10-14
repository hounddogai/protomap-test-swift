import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a tiered slot mapping must pass. Check returns its problems, or none.
    protocol TieredSlotMappingRule {
        func check(_ item: TieredSlotMapping) -> [String]
    }

    final class TieredSlotMappingRequiredTitleRule: TieredSlotMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredSlotMapping) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredSlotMappingCeilingRangeRule: TieredSlotMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredSlotMapping) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredSlotMappingContactEmailLengthRule: TieredSlotMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredSlotMapping) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredSlotMappingCodePrefixRule: TieredSlotMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredSlotMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered slot mapping.
    final class TieredSlotMappingValidator {
        var rules: [any TieredSlotMappingRule]

        init(rules: [any TieredSlotMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredSlotMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredSlotMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredSlotMapping]) -> [String: [String]] {
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

    static func defaultTieredSlotMappingValidator() -> TieredSlotMappingValidator {
        return TieredSlotMappingValidator(
            rules: [
                TieredSlotMappingRequiredTitleRule(message: "tiered slot mapping needs this field"),
                TieredSlotMappingCeilingRangeRule(min: 0.9, max: 2255.7),
                TieredSlotMappingContactEmailLengthRule(maxLength: 16),
                TieredSlotMappingCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
