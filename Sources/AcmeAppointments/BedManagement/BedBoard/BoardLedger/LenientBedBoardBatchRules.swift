import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a lenient bed board batch must pass. Check returns its problems, or none.
    protocol LenientBedBoardBatchRule {
        func check(_ item: LenientBedBoardBatch) -> [String]
    }

    final class LenientBedBoardBatchCodePrefixRule: LenientBedBoardBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientBedBoardBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientBedBoardBatchAllowedCodeRule: LenientBedBoardBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientBedBoardBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class LenientBedBoardBatchQuantityRangeRule: LenientBedBoardBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientBedBoardBatch) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient bed board batch.
    final class LenientBedBoardBatchValidator {
        var rules: [any LenientBedBoardBatchRule]

        init(rules: [any LenientBedBoardBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientBedBoardBatch) -> [String] {
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

        func requireValid(_ item: LenientBedBoardBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientBedBoardBatch]) -> [String: [String]] {
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

    static func defaultLenientBedBoardBatchValidator() -> LenientBedBoardBatchValidator {
        return LenientBedBoardBatchValidator(
            rules: [
                LenientBedBoardBatchCodePrefixRule(prefix: "Q"),
                LenientBedBoardBatchAllowedCodeRule(allowed: []),
                LenientBedBoardBatchQuantityRangeRule(min: 64, max: 255),
            ]
        )
    }
}
