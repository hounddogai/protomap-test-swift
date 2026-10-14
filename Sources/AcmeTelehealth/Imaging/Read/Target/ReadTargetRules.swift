import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read target must pass. Check returns its problems, or none.
    protocol ReadTargetRule {
        func check(_ item: ReadTarget) -> [String]
    }

    final class ReadTargetOwnerIDLengthRule: ReadTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadTarget) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadTargetEncounterIDLengthRule: ReadTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadTarget) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadTargetCodePrefixRule: ReadTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReadTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReadTargetLimitRangeRule: ReadTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadTarget) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a read target.
    final class ReadTargetValidator {
        var rules: [any ReadTargetRule]

        init(rules: [any ReadTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadTarget) -> [String] {
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

        func requireValid(_ item: ReadTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadTarget]) -> [String: [String]] {
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

    static func defaultReadTargetValidator() -> ReadTargetValidator {
        return ReadTargetValidator(
            rules: [
                ReadTargetOwnerIDLengthRule(maxLength: 1000),
                ReadTargetEncounterIDLengthRule(maxLength: 120),
                ReadTargetCodePrefixRule(prefix: "OPS"),
                ReadTargetLimitRangeRule(min: 80, max: 1000),
            ]
        )
    }
}
