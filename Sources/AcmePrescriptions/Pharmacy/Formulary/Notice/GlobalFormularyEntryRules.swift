import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a global formulary entry must pass. Check returns its problems, or none.
    protocol GlobalFormularyEntryRule {
        func check(_ item: GlobalFormularyEntry) -> [String]
    }

    final class GlobalFormularyEntryAllowedPayerRule: GlobalFormularyEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalFormularyEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is too long"]
            }
            return []
        }
    }

    final class GlobalFormularyEntryCodePrefixRule: GlobalFormularyEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalFormularyEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalFormularyEntryRevisionRangeRule: GlobalFormularyEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalFormularyEntry) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a global formulary entry.
    final class GlobalFormularyEntryValidator {
        var rules: [any GlobalFormularyEntryRule]

        init(rules: [any GlobalFormularyEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalFormularyEntry) -> [String] {
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

        func requireValid(_ item: GlobalFormularyEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalFormularyEntry]) -> [String: [String]] {
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

    static func defaultGlobalFormularyEntryValidator() -> GlobalFormularyEntryValidator {
        return GlobalFormularyEntryValidator(
            rules: [
                GlobalFormularyEntryAllowedPayerRule(allowed: []),
                GlobalFormularyEntryCodePrefixRule(prefix: "OPS"),
                GlobalFormularyEntryRevisionRangeRule(min: 120, max: 1000),
            ]
        )
    }
}
