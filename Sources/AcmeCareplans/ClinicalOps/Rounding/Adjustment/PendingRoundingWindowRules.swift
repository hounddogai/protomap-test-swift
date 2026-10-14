import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a pending rounding window must pass. Check returns its problems, or none.
    protocol PendingRoundingWindowRule {
        func check(_ item: PendingRoundingWindow) -> [String]
    }

    final class PendingRoundingWindowRequiredCodeRule: PendingRoundingWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingRoundingWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingRoundingWindowTimezoneLengthRule: PendingRoundingWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingRoundingWindow) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingRoundingWindowCodeLengthRule: PendingRoundingWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingRoundingWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingRoundingWindowRequiredLabelRule: PendingRoundingWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingRoundingWindow) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingRoundingWindowQuantityRangeRule: PendingRoundingWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingRoundingWindow) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingRoundingWindowPatientRefLengthRule: PendingRoundingWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingRoundingWindow) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending rounding window.
    final class PendingRoundingWindowValidator {
        var rules: [any PendingRoundingWindowRule]

        init(rules: [any PendingRoundingWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingRoundingWindow) -> [String] {
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

        func requireValid(_ item: PendingRoundingWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingRoundingWindow]) -> [String: [String]] {
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

    static func defaultPendingRoundingWindowValidator() -> PendingRoundingWindowValidator {
        return PendingRoundingWindowValidator(
            rules: [
                PendingRoundingWindowRequiredCodeRule(message: "pending rounding window needs an entry"),
                PendingRoundingWindowTimezoneLengthRule(maxLength: 64),
                PendingRoundingWindowCodeLengthRule(maxLength: 16),
                PendingRoundingWindowRequiredLabelRule(message: "pending rounding window needs a value"),
                PendingRoundingWindowQuantityRangeRule(min: 64, max: 255),
                PendingRoundingWindowPatientRefLengthRule(maxLength: 255),
            ]
        )
    }
}
