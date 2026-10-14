import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board policy must pass. Check returns its problems, or none.
    protocol BedBoardPolicyRule {
        func check(_ item: BedBoardPolicy) -> [String]
    }

    final class BedBoardPolicyAllowedTitleRule: BedBoardPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BedBoardPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is below minimum"]
            }
            return []
        }
    }

    final class BedBoardPolicyPhoneLengthRule: BedBoardPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardPolicy) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardPolicyQuantityRangeRule: BedBoardPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardPolicy) -> [String] {
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

    final class BedBoardPolicyRequiredPhoneRule: BedBoardPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardPolicy) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardPolicyCodeLengthRule: BedBoardPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardPolicyAcuityRangeRule: BedBoardPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardPolicy) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a bed board policy.
    final class BedBoardPolicyValidator {
        var rules: [any BedBoardPolicyRule]

        init(rules: [any BedBoardPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BedBoardPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardPolicy]) -> [String: [String]] {
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

    static func defaultBedBoardPolicyValidator() -> BedBoardPolicyValidator {
        return BedBoardPolicyValidator(
            rules: [
                BedBoardPolicyAllowedTitleRule(allowed: ["legacy"]),
                BedBoardPolicyPhoneLengthRule(maxLength: 120),
                BedBoardPolicyQuantityRangeRule(min: 80, max: 255),
                BedBoardPolicyRequiredPhoneRule(message: "bed board policy needs this field"),
                BedBoardPolicyCodeLengthRule(maxLength: 255),
                BedBoardPolicyAcuityRangeRule(min: 64, max: 1000),
            ]
        )
    }
}
