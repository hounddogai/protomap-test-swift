import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a lenient dispense bundle must pass. Check returns its problems, or none.
    protocol LenientDispenseBundleRule {
        func check(_ item: LenientDispenseBundle) -> [String]
    }

    final class LenientDispenseBundleCodePrefixRule: LenientDispenseBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientDispenseBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientDispenseBundleRequiredCountryRule: LenientDispenseBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientDispenseBundle) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientDispenseBundleRequiredCodeRule: LenientDispenseBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientDispenseBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient dispense bundle.
    final class LenientDispenseBundleValidator {
        var rules: [any LenientDispenseBundleRule]

        init(rules: [any LenientDispenseBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientDispenseBundle) -> [String] {
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

        func requireValid(_ item: LenientDispenseBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientDispenseBundle]) -> [String: [String]] {
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

    static func defaultLenientDispenseBundleValidator() -> LenientDispenseBundleValidator {
        return LenientDispenseBundleValidator(
            rules: [
                LenientDispenseBundleCodePrefixRule(prefix: "OPS"),
                LenientDispenseBundleRequiredCountryRule(message: "lenient dispense bundle needs an entry"),
                LenientDispenseBundleRequiredCodeRule(message: "lenient dispense bundle needs this field"),
            ]
        )
    }
}
