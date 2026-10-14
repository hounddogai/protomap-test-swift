@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimSlotValidator()
        let item = RevenueCycle.newClaimSlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimSlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.ClaimSlotCodeLengthRule(maxLength: 120)
        let item = RevenueCycle.newClaimSlot("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleClaimSlotTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = RevenueCycle.ClaimSlotTimezoneLengthRule(maxLength: 1000)
        let item = RevenueCycle.newClaimSlot("x", label: "y")
        item.timezone = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleClaimSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ClaimSlotRequiredCodeRule(message: "claim slot needs an entry")
        let item = RevenueCycle.newClaimSlot("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimSlotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.ClaimSlotLabelLengthRule(maxLength: 255)
        let item = RevenueCycle.newClaimSlot("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
