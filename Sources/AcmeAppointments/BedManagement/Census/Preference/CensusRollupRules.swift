import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census rollup must pass. Check returns its problems, or none.
    protocol CensusRollupRule {
        func check(_ item: CensusRollup) -> [String]
    }

    final class CensusRollupRequiredProcedureCodeRule: CensusRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusRollup) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusRollupRequiredNameRule: CensusRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusRollup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusRollupCodePrefixRule: CensusRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CensusRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a census rollup.
    final class CensusRollupValidator {
        var rules: [any CensusRollupRule]

        init(rules: [any CensusRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CensusRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusRollup]) -> [String: [String]] {
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

    static func defaultCensusRollupValidator() -> CensusRollupValidator {
        return CensusRollupValidator(
            rules: [
                CensusRollupRequiredProcedureCodeRule(message: "census rollup needs this field"),
                CensusRollupRequiredNameRule(message: "census rollup needs this field"),
                CensusRollupCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
