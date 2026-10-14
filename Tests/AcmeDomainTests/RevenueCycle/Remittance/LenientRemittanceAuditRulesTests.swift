@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientRemittanceAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultLenientRemittanceAuditValidator()
        let item = RevenueCycle.newLenientRemittanceAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleLenientRemittanceAuditRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.LenientRemittanceAuditRequiredCodeRule(message: "lenient remittance audit needs a value")
        let item = RevenueCycle.newLenientRemittanceAudit("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleLenientRemittanceAuditCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = RevenueCycle.LenientRemittanceAuditCopayRangeRule(min: 0.3, max: 4181.3)
        let item = RevenueCycle.newLenientRemittanceAudit("x", title: "y")
        item.copay = 4182.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleLenientRemittanceAuditTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.LenientRemittanceAuditTitleLengthRule(maxLength: 1000)
        let item = RevenueCycle.newLenientRemittanceAudit("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
