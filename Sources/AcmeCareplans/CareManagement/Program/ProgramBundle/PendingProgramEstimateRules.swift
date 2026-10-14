import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a pending program estimate must pass. Check returns its problems, or none.
    protocol PendingProgramEstimateRule {
        func check(_ item: PendingProgramEstimate) -> [String]
    }

    final class PendingProgramEstimateCodeLengthRule: PendingProgramEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingProgramEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingProgramEstimateGraceDaysRangeRule: PendingProgramEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingProgramEstimate) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingProgramEstimateAllowedTitleRule: PendingProgramEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingProgramEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is above maximum"]
            }
            return []
        }
    }

    final class PendingProgramEstimateTitleLengthRule: PendingProgramEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingProgramEstimate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingProgramEstimateNameLengthRule: PendingProgramEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingProgramEstimate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending program estimate.
    final class PendingProgramEstimateValidator {
        var rules: [any PendingProgramEstimateRule]

        init(rules: [any PendingProgramEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingProgramEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingProgramEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingProgramEstimate]) -> [String: [String]] {
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

    static func defaultPendingProgramEstimateValidator() -> PendingProgramEstimateValidator {
        return PendingProgramEstimateValidator(
            rules: [
                PendingProgramEstimateCodeLengthRule(maxLength: 86400),
                PendingProgramEstimateGraceDaysRangeRule(min: 32, max: 80),
                PendingProgramEstimateAllowedTitleRule(allowed: ["strict", "primary"]),
                PendingProgramEstimateTitleLengthRule(maxLength: 86400),
                PendingProgramEstimateNameLengthRule(maxLength: 80),
            ]
        )
    }
}
