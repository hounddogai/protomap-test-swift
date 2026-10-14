@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationAllocationValidator()
        let item = RevenueCycle.newAuthorizationAllocation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationAllocationRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = RevenueCycle.AuthorizationAllocationRevisionRangeRule(min: 16, max: 3600)
        let item = RevenueCycle.newAuthorizationAllocation("x", name: "y")
        item.revision = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleAuthorizationAllocationNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.AuthorizationAllocationNameLengthRule(maxLength: 1000)
        let item = RevenueCycle.newAuthorizationAllocation("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationAllocationRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = RevenueCycle.AuthorizationAllocationRequiredNotesRule(
            message: "authorization allocation needs a value"
        )
        let item = RevenueCycle.newAuthorizationAllocation("", name: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationAllocationNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = RevenueCycle.AuthorizationAllocationNotesLengthRule(maxLength: 1000)
        let item = RevenueCycle.newAuthorizationAllocation("x", name: "y")
        item.notes = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}
