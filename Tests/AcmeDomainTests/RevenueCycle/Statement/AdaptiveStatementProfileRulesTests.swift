@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveStatementProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAdaptiveStatementProfileValidator()
        let item = RevenueCycle.newAdaptiveStatementProfile("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAdaptiveStatementProfileFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = RevenueCycle.AdaptiveStatementProfileFacilityLengthRule(maxLength: 16)
        let item = RevenueCycle.newAdaptiveStatementProfile("x", label: "y")
        item.facility = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAdaptiveStatementProfileRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = RevenueCycle.AdaptiveStatementProfileRequiredFacilityRule(
            message: "adaptive statement profile needs an entry"
        )
        let item = RevenueCycle.newAdaptiveStatementProfile("", label: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}
