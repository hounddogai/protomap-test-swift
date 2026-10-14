import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a rolling remittance entry must pass. Check returns its problems, or none.
    protocol RollingRemittanceEntryRule {
        func check(_ item: RollingRemittanceEntry) -> [String]
    }

    final class RollingRemittanceEntryRequiredCategoryRule: RollingRemittanceEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingRemittanceEntry) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingRemittanceEntryCategoryLengthRule: RollingRemittanceEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingRemittanceEntry) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingRemittanceEntryCodePrefixRule: RollingRemittanceEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingRemittanceEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingRemittanceEntryPinnedGuardRule: RollingRemittanceEntryRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RollingRemittanceEntry) -> [String] {
            if item.pinned && (item.floorValue > limit) {
                return ["floor value \(item.floorValue) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling remittance entry.
    final class RollingRemittanceEntryValidator {
        var rules: [any RollingRemittanceEntryRule]

        init(rules: [any RollingRemittanceEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingRemittanceEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingRemittanceEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingRemittanceEntry]) -> [String: [String]] {
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

    static func defaultRollingRemittanceEntryValidator() -> RollingRemittanceEntryValidator {
        return RollingRemittanceEntryValidator(
            rules: [
                RollingRemittanceEntryRequiredCategoryRule(message: "rolling remittance entry needs a value"),
                RollingRemittanceEntryCategoryLengthRule(maxLength: 86400),
                RollingRemittanceEntryCodePrefixRule(prefix: "REF"),
                RollingRemittanceEntryPinnedGuardRule(limit: 0.5),
            ]
        )
    }
}
