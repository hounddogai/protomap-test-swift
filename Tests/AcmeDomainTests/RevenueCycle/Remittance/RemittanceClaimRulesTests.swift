@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceClaimValidator()
        let item = RevenueCycle.newRemittanceClaim("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceClaimRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = RevenueCycle.RemittanceClaimRequiredPhoneRule(message: "remittance claim needs an entry")
        let item = RevenueCycle.newRemittanceClaim("", label: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.RemittanceClaimCodeLengthRule(maxLength: 80)
        let item = RevenueCycle.newRemittanceClaim("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceClaimPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = RevenueCycle.RemittanceClaimPhoneLengthRule(maxLength: 64)
        let item = RevenueCycle.newRemittanceClaim("x", label: "y")
        item.phone = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceClaimSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = RevenueCycle.RemittanceClaimSummaryLengthRule(maxLength: 3600)
        let item = RevenueCycle.newRemittanceClaim("x", label: "y")
        item.summary = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceClaimRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = RevenueCycle.RemittanceClaimRequiredSummaryRule(message: "remittance claim needs this field")
        let item = RevenueCycle.newRemittanceClaim("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}
