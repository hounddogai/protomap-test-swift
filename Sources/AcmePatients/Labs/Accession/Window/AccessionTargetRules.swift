import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession target must pass. Check returns its problems, or none.
    protocol AccessionTargetRule {
        func check(_ item: AccessionTarget) -> [String]
    }

    final class AccessionTargetCodeLengthRule: AccessionTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionTargetBatchSizeRangeRule: AccessionTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionTarget) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AccessionTargetOwnerIDLengthRule: AccessionTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionTarget) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionTargetRequiredCodeRule: AccessionTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a accession target.
    final class AccessionTargetValidator {
        var rules: [any AccessionTargetRule]

        init(rules: [any AccessionTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AccessionTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionTarget]) -> [String: [String]] {
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

    static func defaultAccessionTargetValidator() -> AccessionTargetValidator {
        return AccessionTargetValidator(
            rules: [
                AccessionTargetCodeLengthRule(maxLength: 16),
                AccessionTargetBatchSizeRangeRule(min: 32, max: 120),
                AccessionTargetOwnerIDLengthRule(maxLength: 80),
                AccessionTargetRequiredCodeRule(message: "accession target needs an entry"),
            ]
        )
    }
}
