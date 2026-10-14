import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a batched substitution target must pass. Check returns its problems, or none.
    protocol BatchedSubstitutionTargetRule {
        func check(_ item: BatchedSubstitutionTarget) -> [String]
    }

    final class BatchedSubstitutionTargetCodeLengthRule: BatchedSubstitutionTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedSubstitutionTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedSubstitutionTargetAllowedChannelRule: BatchedSubstitutionTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedSubstitutionTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is stale"]
            }
            return []
        }
    }

    final class BatchedSubstitutionTargetLabelLengthRule: BatchedSubstitutionTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedSubstitutionTarget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedSubstitutionTargetFacilityLengthRule: BatchedSubstitutionTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedSubstitutionTarget) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedSubstitutionTargetChannelLengthRule: BatchedSubstitutionTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedSubstitutionTarget) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedSubstitutionTargetRequiredLabelRule: BatchedSubstitutionTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedSubstitutionTarget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched substitution target.
    final class BatchedSubstitutionTargetValidator {
        var rules: [any BatchedSubstitutionTargetRule]

        init(rules: [any BatchedSubstitutionTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedSubstitutionTarget) -> [String] {
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

        func requireValid(_ item: BatchedSubstitutionTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedSubstitutionTarget]) -> [String: [String]] {
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

    static func defaultBatchedSubstitutionTargetValidator() -> BatchedSubstitutionTargetValidator {
        return BatchedSubstitutionTargetValidator(
            rules: [
                BatchedSubstitutionTargetCodeLengthRule(maxLength: 255),
                BatchedSubstitutionTargetAllowedChannelRule(allowed: ["strict"]),
                BatchedSubstitutionTargetLabelLengthRule(maxLength: 80),
                BatchedSubstitutionTargetFacilityLengthRule(maxLength: 16),
                BatchedSubstitutionTargetChannelLengthRule(maxLength: 3600),
                BatchedSubstitutionTargetRequiredLabelRule(message: "batched substitution target needs this field"),
            ]
        )
    }
}
