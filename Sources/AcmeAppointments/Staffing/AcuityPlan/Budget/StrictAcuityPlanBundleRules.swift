import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a strict acuity plan bundle must pass. Check returns its problems, or none.
    protocol StrictAcuityPlanBundleRule {
        func check(_ item: StrictAcuityPlanBundle) -> [String]
    }

    final class StrictAcuityPlanBundleApprovedGuardRule: StrictAcuityPlanBundleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: StrictAcuityPlanBundle) -> [String] {
            if item.approved && (item.updatedAt > limit) {
                return ["updated at \(item.updatedAt) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class StrictAcuityPlanBundleAllowedExternalRefRule: StrictAcuityPlanBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictAcuityPlanBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is above maximum"]
            }
            return []
        }
    }

    final class StrictAcuityPlanBundleCodeLengthRule: StrictAcuityPlanBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictAcuityPlanBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictAcuityPlanBundleRequiredCodeRule: StrictAcuityPlanBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictAcuityPlanBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictAcuityPlanBundlePatientRefLengthRule: StrictAcuityPlanBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictAcuityPlanBundle) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictAcuityPlanBundleTitleLengthRule: StrictAcuityPlanBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictAcuityPlanBundle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict acuity plan bundle.
    final class StrictAcuityPlanBundleValidator {
        var rules: [any StrictAcuityPlanBundleRule]

        init(rules: [any StrictAcuityPlanBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictAcuityPlanBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictAcuityPlanBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictAcuityPlanBundle]) -> [String: [String]] {
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

    static func defaultStrictAcuityPlanBundleValidator() -> StrictAcuityPlanBundleValidator {
        return StrictAcuityPlanBundleValidator(
            rules: [
                StrictAcuityPlanBundleApprovedGuardRule(limit: 1000),
                StrictAcuityPlanBundleAllowedExternalRefRule(allowed: ["seasonal", "scheduled", "seasonal"]),
                StrictAcuityPlanBundleCodeLengthRule(maxLength: 255),
                StrictAcuityPlanBundleRequiredCodeRule(message: "strict acuity plan bundle needs this field"),
                StrictAcuityPlanBundlePatientRefLengthRule(maxLength: 3600),
                StrictAcuityPlanBundleTitleLengthRule(maxLength: 80),
            ]
        )
    }
}
