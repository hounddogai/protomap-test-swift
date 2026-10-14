import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result claim must pass. Check returns its problems, or none.
    protocol ResultClaimRule {
        func check(_ item: ResultClaim) -> [String]
    }

    final class ResultClaimWardLengthRule: ResultClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultClaim) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultClaimDiagnosisCodeLengthRule: ResultClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultClaim) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultClaimRequiredTitleRule: ResultClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultClaim) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultClaimQuantityRangeRule: ResultClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultClaim) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ResultClaimCodePrefixRule: ResultClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ResultClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a result claim.
    final class ResultClaimValidator {
        var rules: [any ResultClaimRule]

        init(rules: [any ResultClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultClaim) -> [String] {
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

        func requireValid(_ item: ResultClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultClaim]) -> [String: [String]] {
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

    static func defaultResultClaimValidator() -> ResultClaimValidator {
        return ResultClaimValidator(
            rules: [
                ResultClaimWardLengthRule(maxLength: 64),
                ResultClaimDiagnosisCodeLengthRule(maxLength: 86400),
                ResultClaimRequiredTitleRule(message: "result claim needs an entry"),
                ResultClaimQuantityRangeRule(min: 64, max: 255),
                ResultClaimCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
