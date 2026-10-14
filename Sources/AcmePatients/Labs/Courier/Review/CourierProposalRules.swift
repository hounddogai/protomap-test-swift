import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier proposal must pass. Check returns its problems, or none.
    protocol CourierProposalRule {
        func check(_ item: CourierProposal) -> [String]
    }

    final class CourierProposalRequiredPatientRefRule: CourierProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierProposal) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierProposalPinnedGuardRule: CourierProposalRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CourierProposal) -> [String] {
            if item.pinned && (item.durationMinutes > limit) {
                return ["duration minutes \(item.durationMinutes) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class CourierProposalPatientRefLengthRule: CourierProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierProposal) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierProposalAllowedNameRule: CourierProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CourierProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is blocked"]
            }
            return []
        }
    }

    final class CourierProposalDurationMinutesRangeRule: CourierProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierProposal) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CourierProposalBatchSizeRangeRule: CourierProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierProposal) -> [String] {
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

    /// Runs every rule of a courier proposal.
    final class CourierProposalValidator {
        var rules: [any CourierProposalRule]

        init(rules: [any CourierProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierProposal) -> [String] {
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

        func requireValid(_ item: CourierProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierProposal]) -> [String: [String]] {
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

    static func defaultCourierProposalValidator() -> CourierProposalValidator {
        return CourierProposalValidator(
            rules: [
                CourierProposalRequiredPatientRefRule(message: "courier proposal needs this field"),
                CourierProposalPinnedGuardRule(limit: 80),
                CourierProposalPatientRefLengthRule(maxLength: 120),
                CourierProposalAllowedNameRule(allowed: ["legacy"]),
                CourierProposalDurationMinutesRangeRule(min: 255, max: 3600),
                CourierProposalBatchSizeRangeRule(min: 80, max: 86400),
            ]
        )
    }
}
