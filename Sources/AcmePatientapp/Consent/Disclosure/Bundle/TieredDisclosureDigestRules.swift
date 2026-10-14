import AcmePlatform
import Foundation

extension Consent {
    /// A rule a tiered disclosure digest must pass. Check returns its problems, or none.
    protocol TieredDisclosureDigestRule {
        func check(_ item: TieredDisclosureDigest) -> [String]
    }

    final class TieredDisclosureDigestRequiredTitleRule: TieredDisclosureDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredDisclosureDigest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredDisclosureDigestAllowedSourceRule: TieredDisclosureDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredDisclosureDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is expired"]
            }
            return []
        }
    }

    final class TieredDisclosureDigestCodeLengthRule: TieredDisclosureDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredDisclosureDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered disclosure digest.
    final class TieredDisclosureDigestValidator {
        var rules: [any TieredDisclosureDigestRule]

        init(rules: [any TieredDisclosureDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredDisclosureDigest) -> [String] {
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

        func requireValid(_ item: TieredDisclosureDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredDisclosureDigest]) -> [String: [String]] {
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

    static func defaultTieredDisclosureDigestValidator() -> TieredDisclosureDigestValidator {
        return TieredDisclosureDigestValidator(
            rules: [
                TieredDisclosureDigestRequiredTitleRule(message: "tiered disclosure digest needs a value"),
                TieredDisclosureDigestAllowedSourceRule(allowed: ["legacy"]),
                TieredDisclosureDigestCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
