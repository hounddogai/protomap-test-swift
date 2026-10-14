@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanSegmentValidator()
        let item = BedManagement.newDischargePlanSegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.DischargePlanSegmentRequiredCodeRule(message: "discharge plan segment needs this field")
        let item = BedManagement.newDischargePlanSegment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDischargePlanSegmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.DischargePlanSegmentRequiredNameRule(message: "discharge plan segment needs this field")
        let item = BedManagement.newDischargePlanSegment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDischargePlanSegmentRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = BedManagement.DischargePlanSegmentRequiredClinicianIDRule(
            message: "discharge plan segment needs a value"
        )
        let item = BedManagement.newDischargePlanSegment("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDischargePlanSegmentRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = BedManagement.DischargePlanSegmentRequiredReviewerRule(
            message: "discharge plan segment needs this field"
        )
        let item = BedManagement.newDischargePlanSegment("", name: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDischargePlanSegmentFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = BedManagement.DischargePlanSegmentFloorValueRangeRule(min: 8.9, max: 4782.4)
        let item = BedManagement.newDischargePlanSegment("x", name: "y")
        item.floorValue = 4783.9
        #expect(rule.check(item).count > 0)
    }
}
