import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board request must pass. Check returns its problems, or none.
    protocol BedBoardRequestRule {
        func check(_ item: BedBoardRequest) -> [String]
    }

    final class BedBoardRequestCodeLengthRule: BedBoardRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardRequestLimitRangeRule: BedBoardRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardRequest) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BedBoardRequestRequiredRegionRule: BedBoardRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardRequest) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardRequestRequiredCodeRule: BedBoardRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a bed board request.
    final class BedBoardRequestValidator {
        var rules: [any BedBoardRequestRule]

        init(rules: [any BedBoardRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BedBoardRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardRequest]) -> [String: [String]] {
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

    static func defaultBedBoardRequestValidator() -> BedBoardRequestValidator {
        return BedBoardRequestValidator(
            rules: [
                BedBoardRequestCodeLengthRule(maxLength: 32),
                BedBoardRequestLimitRangeRule(min: 64, max: 1000),
                BedBoardRequestRequiredRegionRule(message: "bed board request needs a value"),
                BedBoardRequestRequiredCodeRule(message: "bed board request needs an entry"),
            ]
        )
    }
}
