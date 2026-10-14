import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a manual program rollup must pass. Check returns its problems, or none.
    protocol ManualProgramRollupRule {
        func check(_ item: ManualProgramRollup) -> [String]
    }

    final class ManualProgramRollupRequiredNameRule: ManualProgramRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualProgramRollup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualProgramRollupRequiredRegionRule: ManualProgramRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualProgramRollup) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualProgramRollupCountryLengthRule: ManualProgramRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualProgramRollup) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualProgramRollupApprovedGuardRule: ManualProgramRollupRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ManualProgramRollup) -> [String] {
            if item.approved && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a manual program rollup.
    final class ManualProgramRollupValidator {
        var rules: [any ManualProgramRollupRule]

        init(rules: [any ManualProgramRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualProgramRollup) -> [String] {
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

        func requireValid(_ item: ManualProgramRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualProgramRollup]) -> [String: [String]] {
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

    static func defaultManualProgramRollupValidator() -> ManualProgramRollupValidator {
        return ManualProgramRollupValidator(
            rules: [
                ManualProgramRollupRequiredNameRule(message: "manual program rollup needs an entry"),
                ManualProgramRollupRequiredRegionRule(message: "manual program rollup needs a value"),
                ManualProgramRollupCountryLengthRule(maxLength: 80),
                ManualProgramRollupApprovedGuardRule(limit: 4.5),
            ]
        )
    }
}
