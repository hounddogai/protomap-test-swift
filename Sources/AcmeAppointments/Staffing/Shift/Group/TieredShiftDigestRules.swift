import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a tiered shift digest must pass. Check returns its problems, or none.
    protocol TieredShiftDigestRule {
        func check(_ item: TieredShiftDigest) -> [String]
    }

    final class TieredShiftDigestCodePrefixRule: TieredShiftDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredShiftDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredShiftDigestRequiredCategoryRule: TieredShiftDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredShiftDigest) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredShiftDigestCategoryLengthRule: TieredShiftDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredShiftDigest) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredShiftDigestContactEmailLengthRule: TieredShiftDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredShiftDigest) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredShiftDigestCodeLengthRule: TieredShiftDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredShiftDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered shift digest.
    final class TieredShiftDigestValidator {
        var rules: [any TieredShiftDigestRule]

        init(rules: [any TieredShiftDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredShiftDigest) -> [String] {
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

        func requireValid(_ item: TieredShiftDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredShiftDigest]) -> [String: [String]] {
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

    static func defaultTieredShiftDigestValidator() -> TieredShiftDigestValidator {
        return TieredShiftDigestValidator(
            rules: [
                TieredShiftDigestCodePrefixRule(prefix: "Q"),
                TieredShiftDigestRequiredCategoryRule(message: "tiered shift digest needs this field"),
                TieredShiftDigestCategoryLengthRule(maxLength: 120),
                TieredShiftDigestContactEmailLengthRule(maxLength: 86400),
                TieredShiftDigestCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
