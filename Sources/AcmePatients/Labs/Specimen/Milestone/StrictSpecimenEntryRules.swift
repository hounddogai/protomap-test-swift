import AcmePlatform
import Foundation

extension Labs {
    /// A rule a strict specimen entry must pass. Check returns its problems, or none.
    protocol StrictSpecimenEntryRule {
        func check(_ item: StrictSpecimenEntry) -> [String]
    }

    final class StrictSpecimenEntryNameLengthRule: StrictSpecimenEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictSpecimenEntry) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictSpecimenEntryRequiredCodeRule: StrictSpecimenEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictSpecimenEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictSpecimenEntryChannelLengthRule: StrictSpecimenEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictSpecimenEntry) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictSpecimenEntryWeightRangeRule: StrictSpecimenEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictSpecimenEntry) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictSpecimenEntryAllowedCodeRule: StrictSpecimenEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictSpecimenEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class StrictSpecimenEntryRetriesRangeRule: StrictSpecimenEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictSpecimenEntry) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a strict specimen entry.
    final class StrictSpecimenEntryValidator {
        var rules: [any StrictSpecimenEntryRule]

        init(rules: [any StrictSpecimenEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictSpecimenEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictSpecimenEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictSpecimenEntry]) -> [String: [String]] {
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

    static func defaultStrictSpecimenEntryValidator() -> StrictSpecimenEntryValidator {
        return StrictSpecimenEntryValidator(
            rules: [
                StrictSpecimenEntryNameLengthRule(maxLength: 16),
                StrictSpecimenEntryRequiredCodeRule(message: "strict specimen entry needs an entry"),
                StrictSpecimenEntryChannelLengthRule(maxLength: 64),
                StrictSpecimenEntryWeightRangeRule(min: 8.1, max: 4153.9),
                StrictSpecimenEntryAllowedCodeRule(allowed: ["primary", "default"]),
                StrictSpecimenEntryRetriesRangeRule(min: 64, max: 120),
            ]
        )
    }
}
