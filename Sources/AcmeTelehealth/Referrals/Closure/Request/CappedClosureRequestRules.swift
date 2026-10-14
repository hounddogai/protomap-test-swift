import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a capped closure request must pass. Check returns its problems, or none.
    protocol CappedClosureRequestRule {
        func check(_ item: CappedClosureRequest) -> [String]
    }

    final class CappedClosureRequestRequiredCurrencyRule: CappedClosureRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedClosureRequest) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedClosureRequestRequiredTitleRule: CappedClosureRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedClosureRequest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedClosureRequestCurrencyLengthRule: CappedClosureRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedClosureRequest) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedClosureRequestTitleLengthRule: CappedClosureRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedClosureRequest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedClosureRequestCodeLengthRule: CappedClosureRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedClosureRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedClosureRequestAllowedTitleRule: CappedClosureRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedClosureRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a capped closure request.
    final class CappedClosureRequestValidator {
        var rules: [any CappedClosureRequestRule]

        init(rules: [any CappedClosureRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedClosureRequest) -> [String] {
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

        func requireValid(_ item: CappedClosureRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedClosureRequest]) -> [String: [String]] {
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

    static func defaultCappedClosureRequestValidator() -> CappedClosureRequestValidator {
        return CappedClosureRequestValidator(
            rules: [
                CappedClosureRequestRequiredCurrencyRule(message: "capped closure request needs a value"),
                CappedClosureRequestRequiredTitleRule(message: "capped closure request needs this field"),
                CappedClosureRequestCurrencyLengthRule(maxLength: 120),
                CappedClosureRequestTitleLengthRule(maxLength: 3600),
                CappedClosureRequestCodeLengthRule(maxLength: 86400),
                CappedClosureRequestAllowedTitleRule(allowed: ["global", "tiered"]),
            ]
        )
    }
}
