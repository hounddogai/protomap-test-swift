import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial batch must pass. Check returns its problems, or none.
    protocol DenialBatchRule {
        func check(_ item: DenialBatch) -> [String]
    }

    final class DenialBatchSourceLengthRule: DenialBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialBatch) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialBatchQuantityRangeRule: DenialBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialBatch) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DenialBatchAllowedSpecialtyRule: DenialBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DenialBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a denial batch.
    final class DenialBatchValidator {
        var rules: [any DenialBatchRule]

        init(rules: [any DenialBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DenialBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialBatch]) -> [String: [String]] {
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

    static func defaultDenialBatchValidator() -> DenialBatchValidator {
        return DenialBatchValidator(
            rules: [
                DenialBatchSourceLengthRule(maxLength: 3600),
                DenialBatchQuantityRangeRule(min: 80, max: 3600),
                DenialBatchAllowedSpecialtyRule(allowed: ["global", "manual"]),
            ]
        )
    }
}
