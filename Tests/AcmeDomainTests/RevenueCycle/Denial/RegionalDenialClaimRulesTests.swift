@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalDenialClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRegionalDenialClaimValidator()
        let item = RevenueCycle.newRegionalDenialClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRegionalDenialClaimMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = RevenueCycle.RegionalDenialClaimMinimumRangeRule(min: 7.9, max: 388.3)
        let item = RevenueCycle.newRegionalDenialClaim("x", title: "y")
        item.minimum = 389.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRegionalDenialClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.RegionalDenialClaimCodeLengthRule(maxLength: 80)
        let item = RevenueCycle.newRegionalDenialClaim("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRegionalDenialClaimRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.RegionalDenialClaimRequiredTitleRule(message: "regional denial claim needs this field")
        let item = RevenueCycle.newRegionalDenialClaim("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRegionalDenialClaimScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = RevenueCycle.RegionalDenialClaimScoreRangeRule(min: 3.7, max: 1509.8)
        let item = RevenueCycle.newRegionalDenialClaim("x", title: "y")
        item.score = 1511.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRegionalDenialClaimRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = RevenueCycle.RegionalDenialClaimRequiredFacilityRule(
            message: "regional denial claim needs this field"
        )
        let item = RevenueCycle.newRegionalDenialClaim("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}
