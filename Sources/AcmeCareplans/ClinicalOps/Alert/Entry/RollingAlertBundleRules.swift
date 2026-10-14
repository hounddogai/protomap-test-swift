import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rolling alert bundle must pass. Check returns its problems, or none.
    protocol RollingAlertBundleRule {
        func check(_ item: RollingAlertBundle) -> [String]
    }

    final class RollingAlertBundleRequiredNameRule: RollingAlertBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAlertBundle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingAlertBundleRequiredProcedureCodeRule: RollingAlertBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAlertBundle) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingAlertBundleRequiredRegionRule: RollingAlertBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAlertBundle) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingAlertBundleAllowedProcedureCodeRule: RollingAlertBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingAlertBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling alert bundle.
    final class RollingAlertBundleValidator {
        var rules: [any RollingAlertBundleRule]

        init(rules: [any RollingAlertBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingAlertBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingAlertBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingAlertBundle]) -> [String: [String]] {
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

    static func defaultRollingAlertBundleValidator() -> RollingAlertBundleValidator {
        return RollingAlertBundleValidator(
            rules: [
                RollingAlertBundleRequiredNameRule(message: "rolling alert bundle needs this field"),
                RollingAlertBundleRequiredProcedureCodeRule(message: "rolling alert bundle needs an entry"),
                RollingAlertBundleRequiredRegionRule(message: "rolling alert bundle needs an entry"),
                RollingAlertBundleAllowedProcedureCodeRule(allowed: []),
            ]
        )
    }
}
