import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board target must pass. Check returns its problems, or none.
    protocol BedBoardTargetRule {
        func check(_ item: BedBoardTarget) -> [String]
    }

    final class BedBoardTargetFacilityLengthRule: BedBoardTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardTarget) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardTargetRequiredCodeRule: BedBoardTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardTargetRequiredLabelRule: BedBoardTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardTarget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardTargetLabelLengthRule: BedBoardTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardTarget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardTargetWeightRangeRule: BedBoardTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardTarget) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a bed board target.
    final class BedBoardTargetValidator {
        var rules: [any BedBoardTargetRule]

        init(rules: [any BedBoardTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BedBoardTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardTarget]) -> [String: [String]] {
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

    static func defaultBedBoardTargetValidator() -> BedBoardTargetValidator {
        return BedBoardTargetValidator(
            rules: [
                BedBoardTargetFacilityLengthRule(maxLength: 3600),
                BedBoardTargetRequiredCodeRule(message: "bed board target needs this field"),
                BedBoardTargetRequiredLabelRule(message: "bed board target needs this field"),
                BedBoardTargetLabelLengthRule(maxLength: 32),
                BedBoardTargetWeightRangeRule(min: 9.2, max: 4769.1),
            ]
        )
    }
}
