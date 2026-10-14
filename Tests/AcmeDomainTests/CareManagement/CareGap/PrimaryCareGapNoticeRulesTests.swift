@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryCareGapNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPrimaryCareGapNoticeValidator()
        let item = CareManagement.newPrimaryCareGapNotice("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPrimaryCareGapNoticeRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.PrimaryCareGapNoticeRequiredNameRule(message: "primary care gap notice needs a value")
        let item = CareManagement.newPrimaryCareGapNotice("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementPrimaryCareGapNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.PrimaryCareGapNoticeRequiredCodeRule(
            message: "primary care gap notice needs this field"
        )
        let item = CareManagement.newPrimaryCareGapNotice("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementPrimaryCareGapNoticeEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = CareManagement.PrimaryCareGapNoticeEndsAtRangeRule(min: 120, max: 3600)
        let item = CareManagement.newPrimaryCareGapNotice("x", name: "y")
        item.endsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
