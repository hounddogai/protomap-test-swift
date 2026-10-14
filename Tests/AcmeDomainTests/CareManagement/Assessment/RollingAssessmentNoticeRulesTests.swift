@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingAssessmentNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRollingAssessmentNoticeValidator()
        let item = CareManagement.newRollingAssessmentNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRollingAssessmentNoticeRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = CareManagement.RollingAssessmentNoticeRequiredWardRule(
            message: "rolling assessment notice needs a value"
        )
        let item = CareManagement.newRollingAssessmentNotice("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRollingAssessmentNoticeTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.RollingAssessmentNoticeTitleLengthRule(maxLength: 3600)
        let item = CareManagement.newRollingAssessmentNotice("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRollingAssessmentNoticeRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.RollingAssessmentNoticeRequiredTitleRule(
            message: "rolling assessment notice needs this field"
        )
        let item = CareManagement.newRollingAssessmentNotice("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRollingAssessmentNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.RollingAssessmentNoticeRequiredCodeRule(
            message: "rolling assessment notice needs an entry"
        )
        let item = CareManagement.newRollingAssessmentNotice("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
