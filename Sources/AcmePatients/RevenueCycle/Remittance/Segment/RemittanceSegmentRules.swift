import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance segment must pass. Check returns its problems, or none.
    protocol RemittanceSegmentRule {
        func check(_ item: RemittanceSegment) -> [String]
    }

    final class RemittanceSegmentTitleLengthRule: RemittanceSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceSegment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceSegmentAllowedTimezoneRule: RemittanceSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RemittanceSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is unknown"]
            }
            return []
        }
    }

    final class RemittanceSegmentRequiredTitleRule: RemittanceSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceSegment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceSegmentCostRangeRule: RemittanceSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceSegment) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RemittanceSegmentCodeLengthRule: RemittanceSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceSegmentRequiredTimezoneRule: RemittanceSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceSegment) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a remittance segment.
    final class RemittanceSegmentValidator {
        var rules: [any RemittanceSegmentRule]

        init(rules: [any RemittanceSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceSegment) -> [String] {
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

        func requireValid(_ item: RemittanceSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceSegment]) -> [String: [String]] {
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

    static func defaultRemittanceSegmentValidator() -> RemittanceSegmentValidator {
        return RemittanceSegmentValidator(
            rules: [
                RemittanceSegmentTitleLengthRule(maxLength: 86400),
                RemittanceSegmentAllowedTimezoneRule(allowed: []),
                RemittanceSegmentRequiredTitleRule(message: "remittance segment needs a value"),
                RemittanceSegmentCostRangeRule(min: 8.0, max: 3246.1),
                RemittanceSegmentCodeLengthRule(maxLength: 86400),
                RemittanceSegmentRequiredTimezoneRule(message: "remittance segment needs this field"),
            ]
        )
    }
}
