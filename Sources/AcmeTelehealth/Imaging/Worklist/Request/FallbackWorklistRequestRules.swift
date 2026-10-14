import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a fallback worklist request must pass. Check returns its problems, or none.
    protocol FallbackWorklistRequestRule {
        func check(_ item: FallbackWorklistRequest) -> [String]
    }

    final class FallbackWorklistRequestAllowedCodeRule: FallbackWorklistRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackWorklistRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class FallbackWorklistRequestRegionLengthRule: FallbackWorklistRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackWorklistRequest) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackWorklistRequestCodeLengthRule: FallbackWorklistRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackWorklistRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackWorklistRequestRequiredCodeRule: FallbackWorklistRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackWorklistRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackWorklistRequestLabelLengthRule: FallbackWorklistRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackWorklistRequest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackWorklistRequestRequiredCountryRule: FallbackWorklistRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackWorklistRequest) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback worklist request.
    final class FallbackWorklistRequestValidator {
        var rules: [any FallbackWorklistRequestRule]

        init(rules: [any FallbackWorklistRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackWorklistRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackWorklistRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackWorklistRequest]) -> [String: [String]] {
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

    static func defaultFallbackWorklistRequestValidator() -> FallbackWorklistRequestValidator {
        return FallbackWorklistRequestValidator(
            rules: [
                FallbackWorklistRequestAllowedCodeRule(allowed: ["batched", "strict"]),
                FallbackWorklistRequestRegionLengthRule(maxLength: 120),
                FallbackWorklistRequestCodeLengthRule(maxLength: 3600),
                FallbackWorklistRequestRequiredCodeRule(message: "fallback worklist request needs a value"),
                FallbackWorklistRequestLabelLengthRule(maxLength: 64),
                FallbackWorklistRequestRequiredCountryRule(message: "fallback worklist request needs an entry"),
            ]
        )
    }
}
