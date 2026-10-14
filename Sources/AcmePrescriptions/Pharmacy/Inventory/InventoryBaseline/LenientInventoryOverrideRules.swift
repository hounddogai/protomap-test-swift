import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a lenient inventory override must pass. Check returns its problems, or none.
    protocol LenientInventoryOverrideRule {
        func check(_ item: LenientInventoryOverride) -> [String]
    }

    final class LenientInventoryOverrideRequiredContactEmailRule: LenientInventoryOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientInventoryOverride) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientInventoryOverrideRegionLengthRule: LenientInventoryOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientInventoryOverride) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientInventoryOverrideContactEmailLengthRule: LenientInventoryOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientInventoryOverride) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient inventory override.
    final class LenientInventoryOverrideValidator {
        var rules: [any LenientInventoryOverrideRule]

        init(rules: [any LenientInventoryOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientInventoryOverride) -> [String] {
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

        func requireValid(_ item: LenientInventoryOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientInventoryOverride]) -> [String: [String]] {
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

    static func defaultLenientInventoryOverrideValidator() -> LenientInventoryOverrideValidator {
        return LenientInventoryOverrideValidator(
            rules: [
                LenientInventoryOverrideRequiredContactEmailRule(
                    message: "lenient inventory override needs this field"
                ),
                LenientInventoryOverrideRegionLengthRule(maxLength: 64),
                LenientInventoryOverrideContactEmailLengthRule(maxLength: 32),
            ]
        )
    }
}
