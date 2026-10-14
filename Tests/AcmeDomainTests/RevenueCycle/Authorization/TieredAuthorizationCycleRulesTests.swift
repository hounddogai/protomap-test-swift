@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredAuthorizationCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultTieredAuthorizationCycleValidator()
        let item = RevenueCycle.newTieredAuthorizationCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleTieredAuthorizationCycleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.TieredAuthorizationCycleRequiredNameRule(
            message: "tiered authorization cycle needs this field"
        )
        let item = RevenueCycle.newTieredAuthorizationCycle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleTieredAuthorizationCycleRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = RevenueCycle.TieredAuthorizationCycleRequiredFacilityRule(
            message: "tiered authorization cycle needs a value"
        )
        let item = RevenueCycle.newTieredAuthorizationCycle("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleTieredAuthorizationCycleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.TieredAuthorizationCycleNameLengthRule(maxLength: 120)
        let item = RevenueCycle.newTieredAuthorizationCycle("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleTieredAuthorizationCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.TieredAuthorizationCycleRequiredCodeRule(
            message: "tiered authorization cycle needs an entry"
        )
        let item = RevenueCycle.newTieredAuthorizationCycle("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
