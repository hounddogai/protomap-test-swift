import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board claim must pass. Check returns its problems, or none.
    protocol BedBoardClaimRule {
        func check(_ item: BedBoardClaim) -> [String]
    }

    final class BedBoardClaimRequiredCodeRule: BedBoardClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardClaimCodeLengthRule: BedBoardClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardClaimNameLengthRule: BedBoardClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardClaim) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardClaimLocaleLengthRule: BedBoardClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardClaim) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a bed board claim.
    final class BedBoardClaimValidator {
        var rules: [any BedBoardClaimRule]

        init(rules: [any BedBoardClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BedBoardClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardClaim]) -> [String: [String]] {
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

    static func defaultBedBoardClaimValidator() -> BedBoardClaimValidator {
        return BedBoardClaimValidator(
            rules: [
                BedBoardClaimRequiredCodeRule(message: "bed board claim needs an entry"),
                BedBoardClaimCodeLengthRule(maxLength: 1000),
                BedBoardClaimNameLengthRule(maxLength: 16),
                BedBoardClaimLocaleLengthRule(maxLength: 120),
            ]
        )
    }
}
