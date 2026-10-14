import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set preference must pass. Check returns its problems, or none.
    protocol OrderSetPreferenceRule {
        func check(_ item: OrderSetPreference) -> [String]
    }

    final class OrderSetPreferenceAllowedOwnerIDRule: OrderSetPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OrderSetPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is unknown"]
            }
            return []
        }
    }

    final class OrderSetPreferenceRequiredCodeRule: OrderSetPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetPreferenceCodeLengthRule: OrderSetPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetPreferenceRequiredLabelRule: OrderSetPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetPreference) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetPreferenceCodePrefixRule: OrderSetPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OrderSetPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class OrderSetPreferenceLabelLengthRule: OrderSetPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetPreference) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a order set preference.
    final class OrderSetPreferenceValidator {
        var rules: [any OrderSetPreferenceRule]

        init(rules: [any OrderSetPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetPreference) -> [String] {
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

        func requireValid(_ item: OrderSetPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetPreference]) -> [String: [String]] {
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

    static func defaultOrderSetPreferenceValidator() -> OrderSetPreferenceValidator {
        return OrderSetPreferenceValidator(
            rules: [
                OrderSetPreferenceAllowedOwnerIDRule(allowed: ["manual"]),
                OrderSetPreferenceRequiredCodeRule(message: "order set preference needs a value"),
                OrderSetPreferenceCodeLengthRule(maxLength: 1000),
                OrderSetPreferenceRequiredLabelRule(message: "order set preference needs an entry"),
                OrderSetPreferenceCodePrefixRule(prefix: "OPS"),
                OrderSetPreferenceLabelLengthRule(maxLength: 1000),
            ]
        )
    }
}
