import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge window must pass. Check returns its problems, or none.
    protocol ChargeWindowRule {
        func check(_ item: ChargeWindow) -> [String]
    }

    final class ChargeWindowAllowedSourceRule: ChargeWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ChargeWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is duplicated"]
            }
            return []
        }
    }

    final class ChargeWindowRequiredSourceRule: ChargeWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeWindow) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeWindowTitleLengthRule: ChargeWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeWindow) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeWindowRevisionRangeRule: ChargeWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeWindow) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ChargeWindowDosageMgRangeRule: ChargeWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeWindow) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ChargeWindowCodePrefixRule: ChargeWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ChargeWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a charge window.
    final class ChargeWindowValidator {
        var rules: [any ChargeWindowRule]

        init(rules: [any ChargeWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ChargeWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeWindow]) -> [String: [String]] {
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

    static func defaultChargeWindowValidator() -> ChargeWindowValidator {
        return ChargeWindowValidator(
            rules: [
                ChargeWindowAllowedSourceRule(allowed: ["lenient"]),
                ChargeWindowRequiredSourceRule(message: "charge window needs a value"),
                ChargeWindowTitleLengthRule(maxLength: 120),
                ChargeWindowRevisionRangeRule(min: 32, max: 255),
                ChargeWindowDosageMgRangeRule(min: 8.6, max: 2004.2),
                ChargeWindowCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
