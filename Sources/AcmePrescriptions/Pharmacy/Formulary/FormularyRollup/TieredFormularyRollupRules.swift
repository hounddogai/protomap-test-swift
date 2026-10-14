import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a tiered formulary rollup must pass. Check returns its problems, or none.
    protocol TieredFormularyRollupRule {
        func check(_ item: TieredFormularyRollup) -> [String]
    }

    final class TieredFormularyRollupCodePrefixRule: TieredFormularyRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredFormularyRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredFormularyRollupRequiredOwnerIDRule: TieredFormularyRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredFormularyRollup) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredFormularyRollupRequiredNameRule: TieredFormularyRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredFormularyRollup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered formulary rollup.
    final class TieredFormularyRollupValidator {
        var rules: [any TieredFormularyRollupRule]

        init(rules: [any TieredFormularyRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredFormularyRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredFormularyRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredFormularyRollup]) -> [String: [String]] {
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

    static func defaultTieredFormularyRollupValidator() -> TieredFormularyRollupValidator {
        return TieredFormularyRollupValidator(
            rules: [
                TieredFormularyRollupCodePrefixRule(prefix: "ACM"),
                TieredFormularyRollupRequiredOwnerIDRule(message: "tiered formulary rollup needs an entry"),
                TieredFormularyRollupRequiredNameRule(message: "tiered formulary rollup needs a value"),
            ]
        )
    }
}
