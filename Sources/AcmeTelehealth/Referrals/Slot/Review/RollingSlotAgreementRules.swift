import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a rolling slot agreement must pass. Check returns its problems, or none.
    protocol RollingSlotAgreementRule {
        func check(_ item: RollingSlotAgreement) -> [String]
    }

    final class RollingSlotAgreementAllowedNameRule: RollingSlotAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingSlotAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is not allowed"]
            }
            return []
        }
    }

    final class RollingSlotAgreementRequiredNameRule: RollingSlotAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingSlotAgreement) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingSlotAgreementBatchSizeRangeRule: RollingSlotAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingSlotAgreement) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingSlotAgreementRequiredCodeRule: RollingSlotAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingSlotAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling slot agreement.
    final class RollingSlotAgreementValidator {
        var rules: [any RollingSlotAgreementRule]

        init(rules: [any RollingSlotAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingSlotAgreement) -> [String] {
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

        func requireValid(_ item: RollingSlotAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingSlotAgreement]) -> [String: [String]] {
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

    static func defaultRollingSlotAgreementValidator() -> RollingSlotAgreementValidator {
        return RollingSlotAgreementValidator(
            rules: [
                RollingSlotAgreementAllowedNameRule(allowed: []),
                RollingSlotAgreementRequiredNameRule(message: "rolling slot agreement needs a value"),
                RollingSlotAgreementBatchSizeRangeRule(min: 1000, max: 3600),
                RollingSlotAgreementRequiredCodeRule(message: "rolling slot agreement needs a value"),
            ]
        )
    }
}
