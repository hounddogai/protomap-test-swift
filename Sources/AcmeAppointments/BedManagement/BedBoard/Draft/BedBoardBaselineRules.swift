import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board baseline must pass. Check returns its problems, or none.
    protocol BedBoardBaselineRule {
        func check(_ item: BedBoardBaseline) -> [String]
    }

    final class BedBoardBaselineAllowedCodeRule: BedBoardBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BedBoardBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class BedBoardBaselinePhoneLengthRule: BedBoardBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardBaseline) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardBaselineMinimumRangeRule: BedBoardBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardBaseline) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a bed board baseline.
    final class BedBoardBaselineValidator {
        var rules: [any BedBoardBaselineRule]

        init(rules: [any BedBoardBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardBaseline) -> [String] {
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

        func requireValid(_ item: BedBoardBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardBaseline]) -> [String: [String]] {
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

    static func defaultBedBoardBaselineValidator() -> BedBoardBaselineValidator {
        return BedBoardBaselineValidator(
            rules: [
                BedBoardBaselineAllowedCodeRule(allowed: ["strict", "scheduled", "legacy"]),
                BedBoardBaselinePhoneLengthRule(maxLength: 16),
                BedBoardBaselineMinimumRangeRule(min: 3.7, max: 1856.2),
            ]
        )
    }
}
