import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a weighted handoff exception must pass. Check returns its problems, or none.
    protocol WeightedHandoffExceptionRule {
        func check(_ item: WeightedHandoffException) -> [String]
    }

    final class WeightedHandoffExceptionLabelLengthRule: WeightedHandoffExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedHandoffException) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedHandoffExceptionCodeLengthRule: WeightedHandoffExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedHandoffException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedHandoffExceptionFacilityLengthRule: WeightedHandoffExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedHandoffException) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedHandoffExceptionArchivedGuardRule: WeightedHandoffExceptionRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: WeightedHandoffException) -> [String] {
            if item.archived && (item.createdAt > limit) {
                return ["created at \(item.createdAt) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class WeightedHandoffExceptionRequiredChecksumRule: WeightedHandoffExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedHandoffException) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedHandoffExceptionChecksumLengthRule: WeightedHandoffExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedHandoffException) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted handoff exception.
    final class WeightedHandoffExceptionValidator {
        var rules: [any WeightedHandoffExceptionRule]

        init(rules: [any WeightedHandoffExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedHandoffException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedHandoffException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedHandoffException]) -> [String: [String]] {
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

    static func defaultWeightedHandoffExceptionValidator() -> WeightedHandoffExceptionValidator {
        return WeightedHandoffExceptionValidator(
            rules: [
                WeightedHandoffExceptionLabelLengthRule(maxLength: 64),
                WeightedHandoffExceptionCodeLengthRule(maxLength: 120),
                WeightedHandoffExceptionFacilityLengthRule(maxLength: 86400),
                WeightedHandoffExceptionArchivedGuardRule(limit: 1000),
                WeightedHandoffExceptionRequiredChecksumRule(message: "weighted handoff exception needs an entry"),
                WeightedHandoffExceptionChecksumLengthRule(maxLength: 120),
            ]
        )
    }
}
