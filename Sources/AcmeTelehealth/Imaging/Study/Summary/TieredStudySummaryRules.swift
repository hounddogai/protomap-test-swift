import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered study summary must pass. Check returns its problems, or none.
    protocol TieredStudySummaryRule {
        func check(_ item: TieredStudySummary) -> [String]
    }

    final class TieredStudySummaryPatientRefLengthRule: TieredStudySummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredStudySummary) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredStudySummaryRegionLengthRule: TieredStudySummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredStudySummary) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredStudySummaryNameLengthRule: TieredStudySummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredStudySummary) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredStudySummaryAllowedNameRule: TieredStudySummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredStudySummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered study summary.
    final class TieredStudySummaryValidator {
        var rules: [any TieredStudySummaryRule]

        init(rules: [any TieredStudySummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredStudySummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredStudySummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredStudySummary]) -> [String: [String]] {
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

    static func defaultTieredStudySummaryValidator() -> TieredStudySummaryValidator {
        return TieredStudySummaryValidator(
            rules: [
                TieredStudySummaryPatientRefLengthRule(maxLength: 32),
                TieredStudySummaryRegionLengthRule(maxLength: 255),
                TieredStudySummaryNameLengthRule(maxLength: 80),
                TieredStudySummaryAllowedNameRule(allowed: ["batched", "strict"]),
            ]
        )
    }
}
