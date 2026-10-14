import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure draft must pass. Check returns its problems, or none.
    protocol DisclosureDraftRule {
        func check(_ item: DisclosureDraft) -> [String]
    }

    final class DisclosureDraftLabelLengthRule: DisclosureDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureDraft) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureDraftRequiredSegmentRule: DisclosureDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureDraft) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureDraftCopayRangeRule: DisclosureDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureDraft) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DisclosureDraftWardLengthRule: DisclosureDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureDraft) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureDraftAllowedSegmentRule: DisclosureDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DisclosureDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.segment)) {
                return ["segment \(item.segment) is out of range"]
            }
            return []
        }
    }

    final class DisclosureDraftRequiredLabelRule: DisclosureDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureDraft) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure draft.
    final class DisclosureDraftValidator {
        var rules: [any DisclosureDraftRule]

        init(rules: [any DisclosureDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DisclosureDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureDraft]) -> [String: [String]] {
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

    static func defaultDisclosureDraftValidator() -> DisclosureDraftValidator {
        return DisclosureDraftValidator(
            rules: [
                DisclosureDraftLabelLengthRule(maxLength: 16),
                DisclosureDraftRequiredSegmentRule(message: "disclosure draft needs an entry"),
                DisclosureDraftCopayRangeRule(min: 7.7, max: 1285.9),
                DisclosureDraftWardLengthRule(maxLength: 64),
                DisclosureDraftAllowedSegmentRule(allowed: ["pending"]),
                DisclosureDraftRequiredLabelRule(message: "disclosure draft needs a value"),
            ]
        )
    }
}
