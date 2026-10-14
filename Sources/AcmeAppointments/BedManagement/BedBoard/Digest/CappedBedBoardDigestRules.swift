import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a capped bed board digest must pass. Check returns its problems, or none.
    protocol CappedBedBoardDigestRule {
        func check(_ item: CappedBedBoardDigest) -> [String]
    }

    final class CappedBedBoardDigestCodePrefixRule: CappedBedBoardDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedBedBoardDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedBedBoardDigestBatchSizeRangeRule: CappedBedBoardDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedBedBoardDigest) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedBedBoardDigestNameLengthRule: CappedBedBoardDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedBedBoardDigest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedBedBoardDigestScoreRangeRule: CappedBedBoardDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedBedBoardDigest) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a capped bed board digest.
    final class CappedBedBoardDigestValidator {
        var rules: [any CappedBedBoardDigestRule]

        init(rules: [any CappedBedBoardDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedBedBoardDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedBedBoardDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedBedBoardDigest]) -> [String: [String]] {
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

    static func defaultCappedBedBoardDigestValidator() -> CappedBedBoardDigestValidator {
        return CappedBedBoardDigestValidator(
            rules: [
                CappedBedBoardDigestCodePrefixRule(prefix: "OPS"),
                CappedBedBoardDigestBatchSizeRangeRule(min: 64, max: 64),
                CappedBedBoardDigestNameLengthRule(maxLength: 16),
                CappedBedBoardDigestScoreRangeRule(min: 1.2, max: 2966.2),
            ]
        )
    }
}
