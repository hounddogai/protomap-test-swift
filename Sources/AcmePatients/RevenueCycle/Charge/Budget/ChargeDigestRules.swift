import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge digest must pass. Check returns its problems, or none.
    protocol ChargeDigestRule {
        func check(_ item: ChargeDigest) -> [String]
    }

    final class ChargeDigestVisitMinutesRangeRule: ChargeDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeDigest) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ChargeDigestAllowedNameRule: ChargeDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ChargeDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is unknown"]
            }
            return []
        }
    }

    final class ChargeDigestOwnerIDLengthRule: ChargeDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeDigest) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeDigestCodeLengthRule: ChargeDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeDigestTitleLengthRule: ChargeDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeDigest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeDigestDiscountRangeRule: ChargeDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeDigest) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a charge digest.
    final class ChargeDigestValidator {
        var rules: [any ChargeDigestRule]

        init(rules: [any ChargeDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ChargeDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeDigest]) -> [String: [String]] {
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

    static func defaultChargeDigestValidator() -> ChargeDigestValidator {
        return ChargeDigestValidator(
            rules: [
                ChargeDigestVisitMinutesRangeRule(min: 16, max: 80),
                ChargeDigestAllowedNameRule(allowed: []),
                ChargeDigestOwnerIDLengthRule(maxLength: 3600),
                ChargeDigestCodeLengthRule(maxLength: 255),
                ChargeDigestTitleLengthRule(maxLength: 64),
                ChargeDigestDiscountRangeRule(min: 7.6, max: 264.1),
            ]
        )
    }
}
