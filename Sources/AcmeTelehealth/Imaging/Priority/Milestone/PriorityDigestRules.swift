import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority digest must pass. Check returns its problems, or none.
    protocol PriorityDigestRule {
        func check(_ item: PriorityDigest) -> [String]
    }

    final class PriorityDigestRequiredCodeRule: PriorityDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityDigestRequiredDescriptionRule: PriorityDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityDigest) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityDigestCodeLengthRule: PriorityDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityDigestBatchSizeRangeRule: PriorityDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityDigest) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a priority digest.
    final class PriorityDigestValidator {
        var rules: [any PriorityDigestRule]

        init(rules: [any PriorityDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityDigest) -> [String] {
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

        func requireValid(_ item: PriorityDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityDigest]) -> [String: [String]] {
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

    static func defaultPriorityDigestValidator() -> PriorityDigestValidator {
        return PriorityDigestValidator(
            rules: [
                PriorityDigestRequiredCodeRule(message: "priority digest needs a value"),
                PriorityDigestRequiredDescriptionRule(message: "priority digest needs a value"),
                PriorityDigestCodeLengthRule(maxLength: 1000),
                PriorityDigestBatchSizeRangeRule(min: 32, max: 120),
            ]
        )
    }
}
