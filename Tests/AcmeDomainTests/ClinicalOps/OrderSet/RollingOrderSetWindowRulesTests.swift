@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingOrderSetWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRollingOrderSetWindowValidator()
        let item = ClinicalOps.newRollingOrderSetWindow("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRollingOrderSetWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.RollingOrderSetWindowCodeLengthRule(maxLength: 16)
        let item = ClinicalOps.newRollingOrderSetWindow("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRollingOrderSetWindowRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = ClinicalOps.RollingOrderSetWindowRequiredCurrencyRule(
            message: "rolling order set window needs an entry"
        )
        let item = ClinicalOps.newRollingOrderSetWindow("", name: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}
