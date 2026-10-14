import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure request must pass. Check returns its problems, or none.
    protocol DisclosureRequestRule {
        func check(_ item: DisclosureRequest) -> [String]
    }

    final class DisclosureRequestRequiredBedRule: DisclosureRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureRequest) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureRequestMinimumRangeRule: DisclosureRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureRequest) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DisclosureRequestBedLengthRule: DisclosureRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureRequest) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureRequestRequiredCodeRule: DisclosureRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureRequestLabelLengthRule: DisclosureRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureRequest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureRequestApprovedGuardRule: DisclosureRequestRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: DisclosureRequest) -> [String] {
            if item.approved && (item.minimum > limit) {
                return ["minimum \(item.minimum) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure request.
    final class DisclosureRequestValidator {
        var rules: [any DisclosureRequestRule]

        init(rules: [any DisclosureRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DisclosureRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureRequest]) -> [String: [String]] {
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

    static func defaultDisclosureRequestValidator() -> DisclosureRequestValidator {
        return DisclosureRequestValidator(
            rules: [
                DisclosureRequestRequiredBedRule(message: "disclosure request needs an entry"),
                DisclosureRequestMinimumRangeRule(min: 4.9, max: 418.8),
                DisclosureRequestBedLengthRule(maxLength: 80),
                DisclosureRequestRequiredCodeRule(message: "disclosure request needs a value"),
                DisclosureRequestLabelLengthRule(maxLength: 1000),
                DisclosureRequestApprovedGuardRule(limit: 1.9),
            ]
        )
    }
}
