import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness baseline must pass. Check returns its problems, or none.
    protocol WitnessBaselineRule {
        func check(_ item: WitnessBaseline) -> [String]
    }

    final class WitnessBaselineRequiredOwnerIDRule: WitnessBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessBaseline) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessBaselineAllowedCodeRule: WitnessBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WitnessBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class WitnessBaselineRequiredCodeRule: WitnessBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessBaselineContactEmailLengthRule: WitnessBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessBaseline) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a witness baseline.
    final class WitnessBaselineValidator {
        var rules: [any WitnessBaselineRule]

        init(rules: [any WitnessBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WitnessBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessBaseline]) -> [String: [String]] {
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

    static func defaultWitnessBaselineValidator() -> WitnessBaselineValidator {
        return WitnessBaselineValidator(
            rules: [
                WitnessBaselineRequiredOwnerIDRule(message: "witness baseline needs a value"),
                WitnessBaselineAllowedCodeRule(allowed: []),
                WitnessBaselineRequiredCodeRule(message: "witness baseline needs a value"),
                WitnessBaselineContactEmailLengthRule(maxLength: 3600),
            ]
        )
    }
}
