import AcmePlatform
import Foundation

extension Labs {
    /// A rule a tiered result request must pass. Check returns its problems, or none.
    protocol TieredResultRequestRule {
        func check(_ item: TieredResultRequest) -> [String]
    }

    final class TieredResultRequestRequiredChannelRule: TieredResultRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredResultRequest) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredResultRequestChannelLengthRule: TieredResultRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredResultRequest) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredResultRequestRequiredCodeRule: TieredResultRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredResultRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered result request.
    final class TieredResultRequestValidator {
        var rules: [any TieredResultRequestRule]

        init(rules: [any TieredResultRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredResultRequest) -> [String] {
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

        func requireValid(_ item: TieredResultRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredResultRequest]) -> [String: [String]] {
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

    static func defaultTieredResultRequestValidator() -> TieredResultRequestValidator {
        return TieredResultRequestValidator(
            rules: [
                TieredResultRequestRequiredChannelRule(message: "tiered result request needs a value"),
                TieredResultRequestChannelLengthRule(maxLength: 1000),
                TieredResultRequestRequiredCodeRule(message: "tiered result request needs a value"),
            ]
        )
    }
}
