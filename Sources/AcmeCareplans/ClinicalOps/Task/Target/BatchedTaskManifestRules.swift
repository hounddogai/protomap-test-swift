import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a batched task manifest must pass. Check returns its problems, or none.
    protocol BatchedTaskManifestRule {
        func check(_ item: BatchedTaskManifest) -> [String]
    }

    final class BatchedTaskManifestWindowDaysRangeRule: BatchedTaskManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedTaskManifest) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedTaskManifestNameLengthRule: BatchedTaskManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedTaskManifest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedTaskManifestRequiredCodeRule: BatchedTaskManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedTaskManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedTaskManifestCodeLengthRule: BatchedTaskManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedTaskManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched task manifest.
    final class BatchedTaskManifestValidator {
        var rules: [any BatchedTaskManifestRule]

        init(rules: [any BatchedTaskManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedTaskManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedTaskManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedTaskManifest]) -> [String: [String]] {
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

    static func defaultBatchedTaskManifestValidator() -> BatchedTaskManifestValidator {
        return BatchedTaskManifestValidator(
            rules: [
                BatchedTaskManifestWindowDaysRangeRule(min: 32, max: 255),
                BatchedTaskManifestNameLengthRule(maxLength: 86400),
                BatchedTaskManifestRequiredCodeRule(message: "batched task manifest needs a value"),
                BatchedTaskManifestCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
