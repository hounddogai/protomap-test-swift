import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range entry must pass. Check returns its problems, or none.
    protocol ReferenceRangeEntryRule {
        func check(_ item: ReferenceRangeEntry) -> [String]
    }

    final class ReferenceRangeEntryRequiredSpecialtyRule: ReferenceRangeEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeEntry) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeEntryFacilityLengthRule: ReferenceRangeEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeEntry) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeEntryExpiresAtRangeRule: ReferenceRangeEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeEntry) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferenceRangeEntryVisibleGuardRule: ReferenceRangeEntryRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ReferenceRangeEntry) -> [String] {
            if item.visible && (item.ceiling > limit) {
                return ["ceiling \(item.ceiling) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class ReferenceRangeEntryTitleLengthRule: ReferenceRangeEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeEntry) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a reference range entry.
    final class ReferenceRangeEntryValidator {
        var rules: [any ReferenceRangeEntryRule]

        init(rules: [any ReferenceRangeEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferenceRangeEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeEntry]) -> [String: [String]] {
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

    static func defaultReferenceRangeEntryValidator() -> ReferenceRangeEntryValidator {
        return ReferenceRangeEntryValidator(
            rules: [
                ReferenceRangeEntryRequiredSpecialtyRule(message: "reference range entry needs this field"),
                ReferenceRangeEntryFacilityLengthRule(maxLength: 32),
                ReferenceRangeEntryExpiresAtRangeRule(min: 32, max: 255),
                ReferenceRangeEntryVisibleGuardRule(limit: 9.3),
                ReferenceRangeEntryTitleLengthRule(maxLength: 120),
            ]
        )
    }
}
