import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a capped program digest must pass. Check returns its problems, or none.
    protocol CappedProgramDigestRule {
        func check(_ item: CappedProgramDigest) -> [String]
    }

    final class CappedProgramDigestBatchSizeRangeRule: CappedProgramDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedProgramDigest) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedProgramDigestCodeLengthRule: CappedProgramDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedProgramDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedProgramDigestRequiredSegmentRule: CappedProgramDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedProgramDigest) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedProgramDigestCreatedAtRangeRule: CappedProgramDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedProgramDigest) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped program digest.
    final class CappedProgramDigestValidator {
        var rules: [any CappedProgramDigestRule]

        init(rules: [any CappedProgramDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedProgramDigest) -> [String] {
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

        func requireValid(_ item: CappedProgramDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedProgramDigest]) -> [String: [String]] {
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

    static func defaultCappedProgramDigestValidator() -> CappedProgramDigestValidator {
        return CappedProgramDigestValidator(
            rules: [
                CappedProgramDigestBatchSizeRangeRule(min: 80, max: 80),
                CappedProgramDigestCodeLengthRule(maxLength: 3600),
                CappedProgramDigestRequiredSegmentRule(message: "capped program digest needs an entry"),
                CappedProgramDigestCreatedAtRangeRule(min: 64, max: 80),
            ]
        )
    }
}
