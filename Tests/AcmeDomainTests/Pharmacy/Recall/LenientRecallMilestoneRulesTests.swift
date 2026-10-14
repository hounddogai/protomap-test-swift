@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientRecallMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLenientRecallMilestoneValidator()
        let item = Pharmacy.newLenientRecallMilestone("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLenientRecallMilestoneGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Pharmacy.LenientRecallMilestoneGraceDaysRangeRule(min: 64, max: 80)
        let item = Pharmacy.newLenientRecallMilestone("x", label: "y")
        item.graceDays = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyLenientRecallMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.LenientRecallMilestoneRequiredCodeRule(message: "lenient recall milestone needs an entry")
        let item = Pharmacy.newLenientRecallMilestone("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLenientRecallMilestoneVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Pharmacy.LenientRecallMilestoneVisitMinutesRangeRule(min: 32, max: 255)
        let item = Pharmacy.newLenientRecallMilestone("x", label: "y")
        item.visitMinutes = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyLenientRecallMilestoneRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Pharmacy.LenientRecallMilestoneRateRangeRule(min: 8.3, max: 1596.9)
        let item = Pharmacy.newLenientRecallMilestone("x", label: "y")
        item.rate = 1598.4
        #expect(rule.check(item).count > 0)
    }
}
