import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance entry must pass. Check returns its problems, or none.
    protocol RemittanceEntryRule {
        func check(_ item: RemittanceEntry) -> [String]
    }

    final class RemittanceEntryNameLengthRule: RemittanceEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceEntry) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceEntryAllowedBedRule: RemittanceEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RemittanceEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.bed)) {
                return ["bed \(item.bed) is too long"]
            }
            return []
        }
    }

    final class RemittanceEntryRequiredCodeRule: RemittanceEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a remittance entry.
    final class RemittanceEntryValidator {
        var rules: [any RemittanceEntryRule]

        init(rules: [any RemittanceEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RemittanceEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceEntry]) -> [String: [String]] {
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

    static func defaultRemittanceEntryValidator() -> RemittanceEntryValidator {
        return RemittanceEntryValidator(
            rules: [
                RemittanceEntryNameLengthRule(maxLength: 255),
                RemittanceEntryAllowedBedRule(allowed: ["primary", "tiered"]),
                RemittanceEntryRequiredCodeRule(message: "remittance entry needs an entry"),
            ]
        )
    }
}
