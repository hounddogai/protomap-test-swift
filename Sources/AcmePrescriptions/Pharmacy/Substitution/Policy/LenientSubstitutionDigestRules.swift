import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a lenient substitution digest must pass. Check returns its problems, or none.
    protocol LenientSubstitutionDigestRule {
        func check(_ item: LenientSubstitutionDigest) -> [String]
    }

    final class LenientSubstitutionDigestRequiredTitleRule: LenientSubstitutionDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientSubstitutionDigest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientSubstitutionDigestCodeLengthRule: LenientSubstitutionDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientSubstitutionDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientSubstitutionDigestPinnedGuardRule: LenientSubstitutionDigestRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LenientSubstitutionDigest) -> [String] {
            if item.pinned && (item.startsAt > limit) {
                return ["starts at \(item.startsAt) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class LenientSubstitutionDigestTitleLengthRule: LenientSubstitutionDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientSubstitutionDigest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientSubstitutionDigestRequiredCodeRule: LenientSubstitutionDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientSubstitutionDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient substitution digest.
    final class LenientSubstitutionDigestValidator {
        var rules: [any LenientSubstitutionDigestRule]

        init(rules: [any LenientSubstitutionDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientSubstitutionDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientSubstitutionDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientSubstitutionDigest]) -> [String: [String]] {
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

    static func defaultLenientSubstitutionDigestValidator() -> LenientSubstitutionDigestValidator {
        return LenientSubstitutionDigestValidator(
            rules: [
                LenientSubstitutionDigestRequiredTitleRule(message: "lenient substitution digest needs an entry"),
                LenientSubstitutionDigestCodeLengthRule(maxLength: 64),
                LenientSubstitutionDigestPinnedGuardRule(limit: 16),
                LenientSubstitutionDigestTitleLengthRule(maxLength: 1000),
                LenientSubstitutionDigestRequiredCodeRule(message: "lenient substitution digest needs this field"),
            ]
        )
    }
}
