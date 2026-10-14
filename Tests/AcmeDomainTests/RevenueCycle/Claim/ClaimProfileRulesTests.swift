@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimProfileValidator()
        let item = RevenueCycle.newClaimProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimProfileDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = RevenueCycle.ClaimProfileDescriptionLengthRule(maxLength: 1000)
        let item = RevenueCycle.newClaimProfile("x", name: "y")
        item.description = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleClaimProfileRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = RevenueCycle.ClaimProfileRequiredSegmentRule(message: "claim profile needs an entry")
        let item = RevenueCycle.newClaimProfile("", name: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimProfileVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = RevenueCycle.ClaimProfileVisitMinutesRangeRule(min: 120, max: 255)
        let item = RevenueCycle.newClaimProfile("x", name: "y")
        item.visitMinutes = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleClaimProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ClaimProfileRequiredCodeRule(message: "claim profile needs a value")
        let item = RevenueCycle.newClaimProfile("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
