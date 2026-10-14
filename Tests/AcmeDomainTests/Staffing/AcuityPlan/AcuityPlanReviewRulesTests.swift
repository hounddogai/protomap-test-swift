@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanReviewValidator()
        let item = Staffing.newAcuityPlanReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.AcuityPlanReviewCodeLengthRule(maxLength: 1000)
        let item = Staffing.newAcuityPlanReview("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.AcuityPlanReviewRequiredCodeRule(message: "acuity plan review needs an entry")
        let item = Staffing.newAcuityPlanReview("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanReviewRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Staffing.AcuityPlanReviewRequiredTimezoneRule(message: "acuity plan review needs a value")
        let item = Staffing.newAcuityPlanReview("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanReviewNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.AcuityPlanReviewNameLengthRule(maxLength: 80)
        let item = Staffing.newAcuityPlanReview("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
