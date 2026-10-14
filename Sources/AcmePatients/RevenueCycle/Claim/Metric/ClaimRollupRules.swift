import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim rollup must pass. Check returns its problems, or none.
    protocol ClaimRollupRule {
        func check(_ item: ClaimRollup) -> [String]
    }

    final class ClaimRollupSegmentLengthRule: ClaimRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimRollup) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimRollupRequiredNameRule: ClaimRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimRollup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimRollupAllowedNameRule: ClaimRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClaimRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a claim rollup.
    final class ClaimRollupValidator {
        var rules: [any ClaimRollupRule]

        init(rules: [any ClaimRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClaimRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimRollup]) -> [String: [String]] {
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

    static func defaultClaimRollupValidator() -> ClaimRollupValidator {
        return ClaimRollupValidator(
            rules: [
                ClaimRollupSegmentLengthRule(maxLength: 32),
                ClaimRollupRequiredNameRule(message: "claim rollup needs a value"),
                ClaimRollupAllowedNameRule(allowed: ["regional"]),
            ]
        )
    }
}
