import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a fallback modality entry must pass. Check returns its problems, or none.
    protocol FallbackModalityEntryRule {
        func check(_ item: FallbackModalityEntry) -> [String]
    }

    final class FallbackModalityEntryCurrencyLengthRule: FallbackModalityEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackModalityEntry) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackModalityEntryRequiredCurrencyRule: FallbackModalityEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackModalityEntry) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackModalityEntryCodePrefixRule: FallbackModalityEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackModalityEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackModalityEntryNameLengthRule: FallbackModalityEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackModalityEntry) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback modality entry.
    final class FallbackModalityEntryValidator {
        var rules: [any FallbackModalityEntryRule]

        init(rules: [any FallbackModalityEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackModalityEntry) -> [String] {
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

        func requireValid(_ item: FallbackModalityEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackModalityEntry]) -> [String: [String]] {
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

    static func defaultFallbackModalityEntryValidator() -> FallbackModalityEntryValidator {
        return FallbackModalityEntryValidator(
            rules: [
                FallbackModalityEntryCurrencyLengthRule(maxLength: 16),
                FallbackModalityEntryRequiredCurrencyRule(message: "fallback modality entry needs an entry"),
                FallbackModalityEntryCodePrefixRule(prefix: "ACM"),
                FallbackModalityEntryNameLengthRule(maxLength: 80),
            ]
        )
    }
}
