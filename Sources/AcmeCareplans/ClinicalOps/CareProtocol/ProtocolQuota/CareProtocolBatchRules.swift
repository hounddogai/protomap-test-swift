import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol batch must pass. Check returns its problems, or none.
    protocol CareProtocolBatchRule {
        func check(_ item: CareProtocolBatch) -> [String]
    }

    final class CareProtocolBatchOwnerIDLengthRule: CareProtocolBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolBatch) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolBatchCopayRangeRule: CareProtocolBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolBatch) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareProtocolBatchAllowedCodeRule: CareProtocolBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol batch.
    final class CareProtocolBatchValidator {
        var rules: [any CareProtocolBatchRule]

        init(rules: [any CareProtocolBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolBatch]) -> [String: [String]] {
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

    static func defaultCareProtocolBatchValidator() -> CareProtocolBatchValidator {
        return CareProtocolBatchValidator(
            rules: [
                CareProtocolBatchOwnerIDLengthRule(maxLength: 255),
                CareProtocolBatchCopayRangeRule(min: 3.4, max: 4928.9),
                CareProtocolBatchAllowedCodeRule(allowed: ["seasonal", "global", "strict"]),
            ]
        )
    }
}
