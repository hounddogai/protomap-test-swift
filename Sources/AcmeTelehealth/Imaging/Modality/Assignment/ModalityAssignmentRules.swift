import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality assignment must pass. Check returns its problems, or none.
    protocol ModalityAssignmentRule {
        func check(_ item: ModalityAssignment) -> [String]
    }

    final class ModalityAssignmentCodeLengthRule: ModalityAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityAssignmentAllowedDescriptionRule: ModalityAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ModalityAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.description)) {
                return ["description \(item.description) is expired"]
            }
            return []
        }
    }

    final class ModalityAssignmentRatioRangeRule: ModalityAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityAssignment) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ModalityAssignmentVersionRangeRule: ModalityAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityAssignment) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ModalityAssignmentCodePrefixRule: ModalityAssignmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ModalityAssignment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ModalityAssignmentRequiredDescriptionRule: ModalityAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityAssignment) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a modality assignment.
    final class ModalityAssignmentValidator {
        var rules: [any ModalityAssignmentRule]

        init(rules: [any ModalityAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityAssignment) -> [String] {
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

        func requireValid(_ item: ModalityAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityAssignment]) -> [String: [String]] {
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

    static func defaultModalityAssignmentValidator() -> ModalityAssignmentValidator {
        return ModalityAssignmentValidator(
            rules: [
                ModalityAssignmentCodeLengthRule(maxLength: 3600),
                ModalityAssignmentAllowedDescriptionRule(allowed: ["batched", "lenient"]),
                ModalityAssignmentRatioRangeRule(min: 2.4, max: 1293.3),
                ModalityAssignmentVersionRangeRule(min: 16, max: 86400),
                ModalityAssignmentCodePrefixRule(prefix: "X"),
                ModalityAssignmentRequiredDescriptionRule(message: "modality assignment needs an entry"),
            ]
        )
    }
}
