import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a tiered care protocol claim must pass. Check returns its problems, or none.
    protocol TieredCareProtocolClaimRule {
        func check(_ item: TieredCareProtocolClaim) -> [String]
    }

    final class TieredCareProtocolClaimCodeLengthRule: TieredCareProtocolClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredCareProtocolClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredCareProtocolClaimCodePrefixRule: TieredCareProtocolClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredCareProtocolClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredCareProtocolClaimProcedureCodeLengthRule: TieredCareProtocolClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredCareProtocolClaim) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredCareProtocolClaimRequiredSpecialtyRule: TieredCareProtocolClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredCareProtocolClaim) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredCareProtocolClaimAcuityRangeRule: TieredCareProtocolClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredCareProtocolClaim) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a tiered care protocol claim.
    final class TieredCareProtocolClaimValidator {
        var rules: [any TieredCareProtocolClaimRule]

        init(rules: [any TieredCareProtocolClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredCareProtocolClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredCareProtocolClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredCareProtocolClaim]) -> [String: [String]] {
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

    static func defaultTieredCareProtocolClaimValidator() -> TieredCareProtocolClaimValidator {
        return TieredCareProtocolClaimValidator(
            rules: [
                TieredCareProtocolClaimCodeLengthRule(maxLength: 16),
                TieredCareProtocolClaimCodePrefixRule(prefix: "ACM"),
                TieredCareProtocolClaimProcedureCodeLengthRule(maxLength: 64),
                TieredCareProtocolClaimRequiredSpecialtyRule(message: "tiered care protocol claim needs this field"),
                TieredCareProtocolClaimAcuityRangeRule(min: 64, max: 86400),
            ]
        )
    }
}
