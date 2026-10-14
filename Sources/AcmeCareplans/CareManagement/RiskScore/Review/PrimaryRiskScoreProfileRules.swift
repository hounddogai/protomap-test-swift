import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a primary risk score profile must pass. Check returns its problems, or none.
    protocol PrimaryRiskScoreProfileRule {
        func check(_ item: PrimaryRiskScoreProfile) -> [String]
    }

    final class PrimaryRiskScoreProfileOwnerIDLengthRule: PrimaryRiskScoreProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryRiskScoreProfile) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryRiskScoreProfileTitleLengthRule: PrimaryRiskScoreProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryRiskScoreProfile) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryRiskScoreProfileAllowedClinicianIDRule: PrimaryRiskScoreProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryRiskScoreProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is stale"]
            }
            return []
        }
    }

    final class PrimaryRiskScoreProfileQuantityRangeRule: PrimaryRiskScoreProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryRiskScoreProfile) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a primary risk score profile.
    final class PrimaryRiskScoreProfileValidator {
        var rules: [any PrimaryRiskScoreProfileRule]

        init(rules: [any PrimaryRiskScoreProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryRiskScoreProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryRiskScoreProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryRiskScoreProfile]) -> [String: [String]] {
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

    static func defaultPrimaryRiskScoreProfileValidator() -> PrimaryRiskScoreProfileValidator {
        return PrimaryRiskScoreProfileValidator(
            rules: [
                PrimaryRiskScoreProfileOwnerIDLengthRule(maxLength: 32),
                PrimaryRiskScoreProfileTitleLengthRule(maxLength: 1000),
                PrimaryRiskScoreProfileAllowedClinicianIDRule(allowed: ["global"]),
                PrimaryRiskScoreProfileQuantityRangeRule(min: 64, max: 255),
            ]
        )
    }
}
