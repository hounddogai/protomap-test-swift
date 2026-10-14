import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a capped slot bundle must pass. Check returns its problems, or none.
    protocol CappedSlotBundleRule {
        func check(_ item: CappedSlotBundle) -> [String]
    }

    final class CappedSlotBundleRequiredCodeRule: CappedSlotBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedSlotBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedSlotBundleCodePrefixRule: CappedSlotBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedSlotBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedSlotBundleAllergyLengthRule: CappedSlotBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedSlotBundle) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedSlotBundleRequiredNameRule: CappedSlotBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedSlotBundle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedSlotBundleActiveGuardRule: CappedSlotBundleRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: CappedSlotBundle) -> [String] {
            if item.active && (item.threshold > limit) {
                return ["threshold \(item.threshold) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class CappedSlotBundleNameLengthRule: CappedSlotBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedSlotBundle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped slot bundle.
    final class CappedSlotBundleValidator {
        var rules: [any CappedSlotBundleRule]

        init(rules: [any CappedSlotBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedSlotBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedSlotBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedSlotBundle]) -> [String: [String]] {
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

    static func defaultCappedSlotBundleValidator() -> CappedSlotBundleValidator {
        return CappedSlotBundleValidator(
            rules: [
                CappedSlotBundleRequiredCodeRule(message: "capped slot bundle needs an entry"),
                CappedSlotBundleCodePrefixRule(prefix: "Q"),
                CappedSlotBundleAllergyLengthRule(maxLength: 120),
                CappedSlotBundleRequiredNameRule(message: "capped slot bundle needs a value"),
                CappedSlotBundleActiveGuardRule(limit: 2.8),
                CappedSlotBundleNameLengthRule(maxLength: 1000),
            ]
        )
    }
}
