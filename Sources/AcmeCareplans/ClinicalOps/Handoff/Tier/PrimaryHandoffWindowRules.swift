import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a primary handoff window must pass. Check returns its problems, or none.
    protocol PrimaryHandoffWindowRule {
        func check(_ item: PrimaryHandoffWindow) -> [String]
    }

    final class PrimaryHandoffWindowBedLengthRule: PrimaryHandoffWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryHandoffWindow) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryHandoffWindowRequiredBedRule: PrimaryHandoffWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryHandoffWindow) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryHandoffWindowRequiredTimezoneRule: PrimaryHandoffWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryHandoffWindow) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryHandoffWindowRateRangeRule: PrimaryHandoffWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryHandoffWindow) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryHandoffWindowCreatedAtRangeRule: PrimaryHandoffWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryHandoffWindow) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary handoff window.
    final class PrimaryHandoffWindowValidator {
        var rules: [any PrimaryHandoffWindowRule]

        init(rules: [any PrimaryHandoffWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryHandoffWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryHandoffWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryHandoffWindow]) -> [String: [String]] {
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

    static func defaultPrimaryHandoffWindowValidator() -> PrimaryHandoffWindowValidator {
        return PrimaryHandoffWindowValidator(
            rules: [
                PrimaryHandoffWindowBedLengthRule(maxLength: 32),
                PrimaryHandoffWindowRequiredBedRule(message: "primary handoff window needs this field"),
                PrimaryHandoffWindowRequiredTimezoneRule(message: "primary handoff window needs this field"),
                PrimaryHandoffWindowRateRangeRule(min: 2.5, max: 867.7),
                PrimaryHandoffWindowCreatedAtRangeRule(min: 80, max: 255),
            ]
        )
    }
}
