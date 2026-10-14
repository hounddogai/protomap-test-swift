import AcmePlatform
import Foundation

extension Labs {
    /// A rule a legacy courier estimate must pass. Check returns its problems, or none.
    protocol LegacyCourierEstimateRule {
        func check(_ item: LegacyCourierEstimate) -> [String]
    }

    final class LegacyCourierEstimateAllowedCodeRule: LegacyCourierEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyCourierEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class LegacyCourierEstimateApprovedGuardRule: LegacyCourierEstimateRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: LegacyCourierEstimate) -> [String] {
            if item.approved && (item.budget > limit) {
                return ["budget \(item.budget) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class LegacyCourierEstimateClinicianIDLengthRule: LegacyCourierEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyCourierEstimate) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy courier estimate.
    final class LegacyCourierEstimateValidator {
        var rules: [any LegacyCourierEstimateRule]

        init(rules: [any LegacyCourierEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyCourierEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyCourierEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyCourierEstimate]) -> [String: [String]] {
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

    static func defaultLegacyCourierEstimateValidator() -> LegacyCourierEstimateValidator {
        return LegacyCourierEstimateValidator(
            rules: [
                LegacyCourierEstimateAllowedCodeRule(allowed: ["scheduled", "regional", "pending"]),
                LegacyCourierEstimateApprovedGuardRule(limit: 7.5),
                LegacyCourierEstimateClinicianIDLengthRule(maxLength: 1000),
            ]
        )
    }
}
