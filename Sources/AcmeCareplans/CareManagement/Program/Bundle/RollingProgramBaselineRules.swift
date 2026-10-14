import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a rolling program baseline must pass. Check returns its problems, or none.
    protocol RollingProgramBaselineRule {
        func check(_ item: RollingProgramBaseline) -> [String]
    }

    final class RollingProgramBaselineSpecialtyLengthRule: RollingProgramBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingProgramBaseline) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingProgramBaselineArchivedGuardRule: RollingProgramBaselineRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RollingProgramBaseline) -> [String] {
            if item.archived && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class RollingProgramBaselineTitleLengthRule: RollingProgramBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingProgramBaseline) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingProgramBaselineAllowedSpecialtyRule: RollingProgramBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingProgramBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling program baseline.
    final class RollingProgramBaselineValidator {
        var rules: [any RollingProgramBaselineRule]

        init(rules: [any RollingProgramBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingProgramBaseline) -> [String] {
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

        func requireValid(_ item: RollingProgramBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingProgramBaseline]) -> [String: [String]] {
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

    static func defaultRollingProgramBaselineValidator() -> RollingProgramBaselineValidator {
        return RollingProgramBaselineValidator(
            rules: [
                RollingProgramBaselineSpecialtyLengthRule(maxLength: 1000),
                RollingProgramBaselineArchivedGuardRule(limit: 0.4),
                RollingProgramBaselineTitleLengthRule(maxLength: 3600),
                RollingProgramBaselineAllowedSpecialtyRule(allowed: ["legacy", "default", "lenient"]),
            ]
        )
    }
}
