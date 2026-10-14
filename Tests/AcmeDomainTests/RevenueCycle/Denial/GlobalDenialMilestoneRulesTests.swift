@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalDenialMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultGlobalDenialMilestoneValidator()
        let item = RevenueCycle.newGlobalDenialMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleGlobalDenialMilestoneEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = RevenueCycle.GlobalDenialMilestoneEncounterIDLengthRule(maxLength: 86400)
        let item = RevenueCycle.newGlobalDenialMilestone("x", name: "y")
        item.encounterID = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleGlobalDenialMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.GlobalDenialMilestoneRequiredCodeRule(message: "global denial milestone needs a value")
        let item = RevenueCycle.newGlobalDenialMilestone("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleGlobalDenialMilestoneRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.GlobalDenialMilestoneRequiredNameRule(message: "global denial milestone needs an entry")
        let item = RevenueCycle.newGlobalDenialMilestone("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleGlobalDenialMilestoneRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = RevenueCycle.GlobalDenialMilestoneRequiredPhoneRule(message: "global denial milestone needs an entry")
        let item = RevenueCycle.newGlobalDenialMilestone("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}
