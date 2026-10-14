import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board entry must pass. Check returns its problems, or none.
    protocol BedBoardEntryRule {
        func check(_ item: BedBoardEntry) -> [String]
    }

    final class BedBoardEntryRequiredCodeRule: BedBoardEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardEntryLabelLengthRule: BedBoardEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardEntry) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardEntryScoreRangeRule: BedBoardEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardEntry) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BedBoardEntryCodePrefixRule: BedBoardEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BedBoardEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BedBoardEntryAllowedLabelRule: BedBoardEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BedBoardEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is blocked"]
            }
            return []
        }
    }

    final class BedBoardEntryVisitMinutesRangeRule: BedBoardEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardEntry) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a bed board entry.
    final class BedBoardEntryValidator {
        var rules: [any BedBoardEntryRule]

        init(rules: [any BedBoardEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BedBoardEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardEntry]) -> [String: [String]] {
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

    static func defaultBedBoardEntryValidator() -> BedBoardEntryValidator {
        return BedBoardEntryValidator(
            rules: [
                BedBoardEntryRequiredCodeRule(message: "bed board entry needs an entry"),
                BedBoardEntryLabelLengthRule(maxLength: 255),
                BedBoardEntryScoreRangeRule(min: 8.5, max: 3402.7),
                BedBoardEntryCodePrefixRule(prefix: "Q"),
                BedBoardEntryAllowedLabelRule(allowed: ["rolling", "weighted"]),
                BedBoardEntryVisitMinutesRangeRule(min: 120, max: 3600),
            ]
        )
    }
}
