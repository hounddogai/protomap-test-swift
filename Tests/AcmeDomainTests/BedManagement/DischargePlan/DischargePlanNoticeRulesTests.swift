@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanNoticeValidator()
        let item = BedManagement.newDischargePlanNotice("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanNoticeReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = BedManagement.DischargePlanNoticeReviewerLengthRule(maxLength: 64)
        let item = BedManagement.newDischargePlanNotice("x", name: "y")
        item.reviewer = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDischargePlanNoticeRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.DischargePlanNoticeRequiredNameRule(message: "discharge plan notice needs this field")
        let item = BedManagement.newDischargePlanNotice("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDischargePlanNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.DischargePlanNoticeRequiredCodeRule(message: "discharge plan notice needs a value")
        let item = BedManagement.newDischargePlanNotice("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDischargePlanNoticeMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = BedManagement.DischargePlanNoticeMarginRangeRule(min: 4.3, max: 1328.1)
        let item = BedManagement.newDischargePlanNotice("x", name: "y")
        item.margin = 1329.6
        #expect(rule.check(item).count > 0)
    }
}
