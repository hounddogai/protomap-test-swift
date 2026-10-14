import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall claim must pass. Check returns its problems, or none.
    protocol RecallClaimRule {
        func check(_ item: RecallClaim) -> [String]
    }

    final class RecallClaimEncounterIDLengthRule: RecallClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallClaim) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallClaimCodePrefixRule: RecallClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RecallClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RecallClaimRequiredEncounterIDRule: RecallClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallClaim) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a recall claim.
    final class RecallClaimValidator {
        var rules: [any RecallClaimRule]

        init(rules: [any RecallClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallClaim) -> [String] {
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

        func requireValid(_ item: RecallClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallClaim]) -> [String: [String]] {
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

    static func defaultRecallClaimValidator() -> RecallClaimValidator {
        return RecallClaimValidator(
            rules: [
                RecallClaimEncounterIDLengthRule(maxLength: 1000),
                RecallClaimCodePrefixRule(prefix: "ACM"),
                RecallClaimRequiredEncounterIDRule(message: "recall claim needs an entry"),
            ]
        )
    }
}
