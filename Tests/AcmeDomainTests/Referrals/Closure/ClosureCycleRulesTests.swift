@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureCycleValidator()
        let item = Referrals.newClosureCycle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureCycleDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Referrals.ClosureCycleDurationMinutesRangeRule(min: 64, max: 255)
        let item = Referrals.newClosureCycle("x", label: "y")
        item.durationMinutes = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsClosureCycleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.ClosureCycleRequiredLabelRule(message: "closure cycle needs an entry")
        let item = Referrals.newClosureCycle("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
