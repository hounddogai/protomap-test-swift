import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a global discharge plan bundle must pass. Check returns its problems, or none.
    protocol GlobalDischargePlanBundleRule {
        func check(_ item: GlobalDischargePlanBundle) -> [String]
    }

    final class GlobalDischargePlanBundleApprovedGuardRule: GlobalDischargePlanBundleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: GlobalDischargePlanBundle) -> [String] {
            if item.approved && (item.startsAt > limit) {
                return ["starts at \(item.startsAt) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class GlobalDischargePlanBundleNameLengthRule: GlobalDischargePlanBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalDischargePlanBundle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalDischargePlanBundleCodeLengthRule: GlobalDischargePlanBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalDischargePlanBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global discharge plan bundle.
    final class GlobalDischargePlanBundleValidator {
        var rules: [any GlobalDischargePlanBundleRule]

        init(rules: [any GlobalDischargePlanBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalDischargePlanBundle) -> [String] {
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

        func requireValid(_ item: GlobalDischargePlanBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalDischargePlanBundle]) -> [String: [String]] {
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

    static func defaultGlobalDischargePlanBundleValidator() -> GlobalDischargePlanBundleValidator {
        return GlobalDischargePlanBundleValidator(
            rules: [
                GlobalDischargePlanBundleApprovedGuardRule(limit: 80),
                GlobalDischargePlanBundleNameLengthRule(maxLength: 255),
                GlobalDischargePlanBundleCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
