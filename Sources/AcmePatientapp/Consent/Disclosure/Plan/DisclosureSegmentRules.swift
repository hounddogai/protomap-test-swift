import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure segment must pass. Check returns its problems, or none.
    protocol DisclosureSegmentRule {
        func check(_ item: DisclosureSegment) -> [String]
    }

    final class DisclosureSegmentRefillsRangeRule: DisclosureSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureSegment) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DisclosureSegmentNameLengthRule: DisclosureSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureSegment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureSegmentAllowedNameRule: DisclosureSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DisclosureSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is too long"]
            }
            return []
        }
    }

    final class DisclosureSegmentRequiredCodeRule: DisclosureSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureSegmentCodeLengthRule: DisclosureSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure segment.
    final class DisclosureSegmentValidator {
        var rules: [any DisclosureSegmentRule]

        init(rules: [any DisclosureSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DisclosureSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureSegment]) -> [String: [String]] {
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

    static func defaultDisclosureSegmentValidator() -> DisclosureSegmentValidator {
        return DisclosureSegmentValidator(
            rules: [
                DisclosureSegmentRefillsRangeRule(min: 32, max: 255),
                DisclosureSegmentNameLengthRule(maxLength: 16),
                DisclosureSegmentAllowedNameRule(allowed: ["tiered", "legacy", "tiered"]),
                DisclosureSegmentRequiredCodeRule(message: "disclosure segment needs a value"),
                DisclosureSegmentCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
