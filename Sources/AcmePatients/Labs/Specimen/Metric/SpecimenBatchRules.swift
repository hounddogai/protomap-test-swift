import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen batch must pass. Check returns its problems, or none.
    protocol SpecimenBatchRule {
        func check(_ item: SpecimenBatch) -> [String]
    }

    final class SpecimenBatchLabelLengthRule: SpecimenBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenBatch) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenBatchSourceLengthRule: SpecimenBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenBatch) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenBatchAllowedCodeRule: SpecimenBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SpecimenBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a specimen batch.
    final class SpecimenBatchValidator {
        var rules: [any SpecimenBatchRule]

        init(rules: [any SpecimenBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenBatch) -> [String] {
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

        func requireValid(_ item: SpecimenBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenBatch]) -> [String: [String]] {
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

    static func defaultSpecimenBatchValidator() -> SpecimenBatchValidator {
        return SpecimenBatchValidator(
            rules: [
                SpecimenBatchLabelLengthRule(maxLength: 80),
                SpecimenBatchSourceLengthRule(maxLength: 255),
                SpecimenBatchAllowedCodeRule(allowed: ["regional"]),
            ]
        )
    }
}
