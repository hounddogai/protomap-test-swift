import AcmePlatform
import Foundation

extension Labs {
    /// A rule a rolling accession score must pass. Check returns its problems, or none.
    protocol RollingAccessionScoreRule {
        func check(_ item: RollingAccessionScore) -> [String]
    }

    final class RollingAccessionScoreCodeLengthRule: RollingAccessionScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingAccessionScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingAccessionScoreNameLengthRule: RollingAccessionScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingAccessionScore) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingAccessionScoreRequiredChecksumRule: RollingAccessionScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAccessionScore) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling accession score.
    final class RollingAccessionScoreValidator {
        var rules: [any RollingAccessionScoreRule]

        init(rules: [any RollingAccessionScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingAccessionScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingAccessionScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingAccessionScore]) -> [String: [String]] {
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

    static func defaultRollingAccessionScoreValidator() -> RollingAccessionScoreValidator {
        return RollingAccessionScoreValidator(
            rules: [
                RollingAccessionScoreCodeLengthRule(maxLength: 3600),
                RollingAccessionScoreNameLengthRule(maxLength: 86400),
                RollingAccessionScoreRequiredChecksumRule(message: "rolling accession score needs an entry"),
            ]
        )
    }
}
