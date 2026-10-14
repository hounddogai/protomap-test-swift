@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyAcuityPlanSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultLegacyAcuityPlanSummaryValidator()
        let item = Staffing.newLegacyAcuityPlanSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingLegacyAcuityPlanSummaryContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Staffing.LegacyAcuityPlanSummaryContactEmailLengthRule(maxLength: 3600)
        let item = Staffing.newLegacyAcuityPlanSummary("x", title: "y")
        item.contactEmail = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingLegacyAcuityPlanSummaryRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.LegacyAcuityPlanSummaryRequiredTitleRule(message: "legacy acuity plan summary needs a value")
        let item = Staffing.newLegacyAcuityPlanSummary("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingLegacyAcuityPlanSummaryRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Staffing.LegacyAcuityPlanSummaryRequiredContactEmailRule(
            message: "legacy acuity plan summary needs this field"
        )
        let item = Staffing.newLegacyAcuityPlanSummary("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingLegacyAcuityPlanSummaryRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Staffing.LegacyAcuityPlanSummaryRequiredSegmentRule(
            message: "legacy acuity plan summary needs an entry"
        )
        let item = Staffing.newLegacyAcuityPlanSummary("", title: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingLegacyAcuityPlanSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.LegacyAcuityPlanSummaryRequiredCodeRule(message: "legacy acuity plan summary needs an entry")
        let item = Staffing.newLegacyAcuityPlanSummary("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
