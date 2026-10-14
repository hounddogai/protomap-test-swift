import AcmePlatform
import Foundation

extension Labs {
    /// A rule a capped specimen tier must pass. Check returns its problems, or none.
    protocol CappedSpecimenTierRule {
        func check(_ item: CappedSpecimenTier) -> [String]
    }

    final class CappedSpecimenTierCodeLengthRule: CappedSpecimenTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedSpecimenTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedSpecimenTierCodePrefixRule: CappedSpecimenTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedSpecimenTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedSpecimenTierSummaryLengthRule: CappedSpecimenTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedSpecimenTier) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped specimen tier.
    final class CappedSpecimenTierValidator {
        var rules: [any CappedSpecimenTierRule]

        init(rules: [any CappedSpecimenTierRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedSpecimenTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedSpecimenTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedSpecimenTier]) -> [String: [String]] {
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

    static func defaultCappedSpecimenTierValidator() -> CappedSpecimenTierValidator {
        return CappedSpecimenTierValidator(
            rules: [
                CappedSpecimenTierCodeLengthRule(maxLength: 80),
                CappedSpecimenTierCodePrefixRule(prefix: "X"),
                CappedSpecimenTierSummaryLengthRule(maxLength: 1000),
            ]
        )
    }
}
