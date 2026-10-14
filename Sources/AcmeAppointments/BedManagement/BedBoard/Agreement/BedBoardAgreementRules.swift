import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board agreement must pass. Check returns its problems, or none.
    protocol BedBoardAgreementRule {
        func check(_ item: BedBoardAgreement) -> [String]
    }

    final class BedBoardAgreementRefillsRangeRule: BedBoardAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardAgreement) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BedBoardAgreementRequiredPatientRefRule: BedBoardAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardAgreement) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardAgreementCodeLengthRule: BedBoardAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardAgreementDurationMinutesRangeRule: BedBoardAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardAgreement) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BedBoardAgreementLabelLengthRule: BedBoardAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardAgreement) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a bed board agreement.
    final class BedBoardAgreementValidator {
        var rules: [any BedBoardAgreementRule]

        init(rules: [any BedBoardAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BedBoardAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardAgreement]) -> [String: [String]] {
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

    static func defaultBedBoardAgreementValidator() -> BedBoardAgreementValidator {
        return BedBoardAgreementValidator(
            rules: [
                BedBoardAgreementRefillsRangeRule(min: 16, max: 16),
                BedBoardAgreementRequiredPatientRefRule(message: "bed board agreement needs an entry"),
                BedBoardAgreementCodeLengthRule(maxLength: 64),
                BedBoardAgreementDurationMinutesRangeRule(min: 64, max: 86400),
                BedBoardAgreementLabelLengthRule(maxLength: 64),
            ]
        )
    }
}
