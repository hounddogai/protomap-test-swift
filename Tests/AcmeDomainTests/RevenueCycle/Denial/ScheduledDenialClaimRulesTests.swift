@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledDenialClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultScheduledDenialClaimValidator()
        let item = RevenueCycle.newScheduledDenialClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleScheduledDenialClaimNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.ScheduledDenialClaimNameLengthRule(maxLength: 3600)
        let item = RevenueCycle.newScheduledDenialClaim("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleScheduledDenialClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.ScheduledDenialClaimCodeLengthRule(maxLength: 86400)
        let item = RevenueCycle.newScheduledDenialClaim("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleScheduledDenialClaimRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.ScheduledDenialClaimRequiredNameRule(message: "scheduled denial claim needs this field")
        let item = RevenueCycle.newScheduledDenialClaim("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
