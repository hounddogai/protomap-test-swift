import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a adaptive bed board batch must pass. Check returns its problems, or none.
    protocol AdaptiveBedBoardBatchRule {
        func check(_ item: AdaptiveBedBoardBatch) -> [String]
    }

    final class AdaptiveBedBoardBatchAllowedNameRule: AdaptiveBedBoardBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveBedBoardBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is expired"]
            }
            return []
        }
    }

    final class AdaptiveBedBoardBatchCodePrefixRule: AdaptiveBedBoardBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveBedBoardBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveBedBoardBatchNameLengthRule: AdaptiveBedBoardBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveBedBoardBatch) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveBedBoardBatchDurationMinutesRangeRule: AdaptiveBedBoardBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveBedBoardBatch) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveBedBoardBatchRatioRangeRule: AdaptiveBedBoardBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveBedBoardBatch) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a adaptive bed board batch.
    final class AdaptiveBedBoardBatchValidator {
        var rules: [any AdaptiveBedBoardBatchRule]

        init(rules: [any AdaptiveBedBoardBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveBedBoardBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveBedBoardBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveBedBoardBatch]) -> [String: [String]] {
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

    static func defaultAdaptiveBedBoardBatchValidator() -> AdaptiveBedBoardBatchValidator {
        return AdaptiveBedBoardBatchValidator(
            rules: [
                AdaptiveBedBoardBatchAllowedNameRule(allowed: ["adaptive", "pending", "primary"]),
                AdaptiveBedBoardBatchCodePrefixRule(prefix: "Q"),
                AdaptiveBedBoardBatchNameLengthRule(maxLength: 32),
                AdaptiveBedBoardBatchDurationMinutesRangeRule(min: 80, max: 120),
                AdaptiveBedBoardBatchRatioRangeRule(min: 2.6, max: 4946.1),
            ]
        )
    }
}
