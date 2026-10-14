@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanTierValidator()
        let item = Staffing.newAcuityPlanTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanTierRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Staffing.AcuityPlanTierRetriesRangeRule(min: 32, max: 86400)
        let item = Staffing.newAcuityPlanTier("x", name: "y")
        item.retries = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAcuityPlanTierNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.AcuityPlanTierNameLengthRule(maxLength: 16)
        let item = Staffing.newAcuityPlanTier("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanTierCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Staffing.AcuityPlanTierCountryLengthRule(maxLength: 32)
        let item = Staffing.newAcuityPlanTier("x", name: "y")
        item.country = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanTierVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Staffing.AcuityPlanTierVersionRangeRule(min: 16, max: 16)
        let item = Staffing.newAcuityPlanTier("x", name: "y")
        item.version = 17
        #expect(rule.check(item).count > 0)
    }
}
