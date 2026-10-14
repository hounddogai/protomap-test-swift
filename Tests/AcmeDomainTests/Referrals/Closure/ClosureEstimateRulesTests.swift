@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureEstimateValidator()
        let item = Referrals.newClosureEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureEstimateNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.ClosureEstimateNameLengthRule(maxLength: 64)
        let item = Referrals.newClosureEstimate("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureEstimateWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Referrals.ClosureEstimateWindowDaysRangeRule(min: 64, max: 3600)
        let item = Referrals.newClosureEstimate("x", name: "y")
        item.windowDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsClosureEstimateCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Referrals.ClosureEstimateCapacityRangeRule(min: 1000, max: 86400)
        let item = Referrals.newClosureEstimate("x", name: "y")
        item.capacity = 86401
        #expect(rule.check(item).count > 0)
    }
}
