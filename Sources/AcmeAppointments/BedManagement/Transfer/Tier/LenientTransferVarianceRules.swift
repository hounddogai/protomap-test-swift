import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a lenient transfer variance must pass. Check returns its problems, or none.
    protocol LenientTransferVarianceRule {
        func check(_ item: LenientTransferVariance) -> [String]
    }

    final class LenientTransferVarianceRequiredCodeRule: LenientTransferVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientTransferVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientTransferVarianceAllowedSpecialtyRule: LenientTransferVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientTransferVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is below minimum"]
            }
            return []
        }
    }

    final class LenientTransferVarianceRequiredTitleRule: LenientTransferVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientTransferVariance) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientTransferVarianceCodeLengthRule: LenientTransferVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientTransferVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientTransferVarianceSpecialtyLengthRule: LenientTransferVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientTransferVariance) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient transfer variance.
    final class LenientTransferVarianceValidator {
        var rules: [any LenientTransferVarianceRule]

        init(rules: [any LenientTransferVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientTransferVariance) -> [String] {
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

        func requireValid(_ item: LenientTransferVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientTransferVariance]) -> [String: [String]] {
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

    static func defaultLenientTransferVarianceValidator() -> LenientTransferVarianceValidator {
        return LenientTransferVarianceValidator(
            rules: [
                LenientTransferVarianceRequiredCodeRule(message: "lenient transfer variance needs this field"),
                LenientTransferVarianceAllowedSpecialtyRule(allowed: ["rolling"]),
                LenientTransferVarianceRequiredTitleRule(message: "lenient transfer variance needs a value"),
                LenientTransferVarianceCodeLengthRule(maxLength: 16),
                LenientTransferVarianceSpecialtyLengthRule(maxLength: 80),
            ]
        )
    }
}
