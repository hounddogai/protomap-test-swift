import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census request must pass. Check returns its problems, or none.
    protocol CensusRequestRule {
        func check(_ item: CensusRequest) -> [String]
    }

    final class CensusRequestCodeLengthRule: CensusRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusRequestSegmentLengthRule: CensusRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusRequest) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusRequestRequiredSegmentRule: CensusRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusRequest) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a census request.
    final class CensusRequestValidator {
        var rules: [any CensusRequestRule]

        init(rules: [any CensusRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CensusRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusRequest]) -> [String: [String]] {
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

    static func defaultCensusRequestValidator() -> CensusRequestValidator {
        return CensusRequestValidator(
            rules: [
                CensusRequestCodeLengthRule(maxLength: 32),
                CensusRequestSegmentLengthRule(maxLength: 120),
                CensusRequestRequiredSegmentRule(message: "census request needs an entry"),
            ]
        )
    }
}
