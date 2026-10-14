import AcmePlatform
import Foundation

extension Labs {
    /// A rule a rolling accession batch must pass. Check returns its problems, or none.
    protocol RollingAccessionBatchRule {
        func check(_ item: RollingAccessionBatch) -> [String]
    }

    final class RollingAccessionBatchPatientRefLengthRule: RollingAccessionBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingAccessionBatch) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingAccessionBatchRequiredSegmentRule: RollingAccessionBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAccessionBatch) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingAccessionBatchRequiredTitleRule: RollingAccessionBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAccessionBatch) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingAccessionBatchRequiredPatientRefRule: RollingAccessionBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAccessionBatch) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingAccessionBatchAllowedCodeRule: RollingAccessionBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingAccessionBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling accession batch.
    final class RollingAccessionBatchValidator {
        var rules: [any RollingAccessionBatchRule]

        init(rules: [any RollingAccessionBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingAccessionBatch) -> [String] {
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

        func requireValid(_ item: RollingAccessionBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingAccessionBatch]) -> [String: [String]] {
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

    static func defaultRollingAccessionBatchValidator() -> RollingAccessionBatchValidator {
        return RollingAccessionBatchValidator(
            rules: [
                RollingAccessionBatchPatientRefLengthRule(maxLength: 3600),
                RollingAccessionBatchRequiredSegmentRule(message: "rolling accession batch needs an entry"),
                RollingAccessionBatchRequiredTitleRule(message: "rolling accession batch needs a value"),
                RollingAccessionBatchRequiredPatientRefRule(message: "rolling accession batch needs this field"),
                RollingAccessionBatchAllowedCodeRule(allowed: ["legacy", "lenient"]),
            ]
        )
    }
}
