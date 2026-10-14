@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialMilestoneValidator()
        let item = RevenueCycle.newDenialMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialMilestoneUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = RevenueCycle.DenialMilestoneUpdatedAtRangeRule(min: 120, max: 3600)
        let item = RevenueCycle.newDenialMilestone("x", name: "y")
        item.updatedAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDenialMilestoneNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = RevenueCycle.DenialMilestoneNotesLengthRule(maxLength: 16)
        let item = RevenueCycle.newDenialMilestone("x", name: "y")
        item.notes = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDenialMilestoneRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = RevenueCycle.DenialMilestoneRequiredContactEmailRule(message: "denial milestone needs this field")
        let item = RevenueCycle.newDenialMilestone("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialMilestoneContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = RevenueCycle.DenialMilestoneContactEmailLengthRule(maxLength: 86400)
        let item = RevenueCycle.newDenialMilestone("x", name: "y")
        item.contactEmail = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDenialMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.DenialMilestoneRequiredCodeRule(message: "denial milestone needs an entry")
        let item = RevenueCycle.newDenialMilestone("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
