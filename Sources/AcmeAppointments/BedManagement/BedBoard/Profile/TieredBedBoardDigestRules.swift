import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a tiered bed board digest must pass. Check returns its problems, or none.
    protocol TieredBedBoardDigestRule {
        func check(_ item: TieredBedBoardDigest) -> [String]
    }

    final class TieredBedBoardDigestRequiredNameRule: TieredBedBoardDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredBedBoardDigest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredBedBoardDigestNameLengthRule: TieredBedBoardDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredBedBoardDigest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredBedBoardDigestCodePrefixRule: TieredBedBoardDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredBedBoardDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredBedBoardDigestCodeLengthRule: TieredBedBoardDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredBedBoardDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered bed board digest.
    final class TieredBedBoardDigestValidator {
        var rules: [any TieredBedBoardDigestRule]

        init(rules: [any TieredBedBoardDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredBedBoardDigest) -> [String] {
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

        func requireValid(_ item: TieredBedBoardDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredBedBoardDigest]) -> [String: [String]] {
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

    static func defaultTieredBedBoardDigestValidator() -> TieredBedBoardDigestValidator {
        return TieredBedBoardDigestValidator(
            rules: [
                TieredBedBoardDigestRequiredNameRule(message: "tiered bed board digest needs this field"),
                TieredBedBoardDigestNameLengthRule(maxLength: 86400),
                TieredBedBoardDigestCodePrefixRule(prefix: "X"),
                TieredBedBoardDigestCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
