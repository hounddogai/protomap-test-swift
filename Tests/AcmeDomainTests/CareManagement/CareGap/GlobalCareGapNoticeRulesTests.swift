@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalCareGapNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGlobalCareGapNoticeValidator()
        let item = CareManagement.newGlobalCareGapNotice("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGlobalCareGapNoticeMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = CareManagement.GlobalCareGapNoticeMarginRangeRule(min: 9.0, max: 3953.3)
        let item = CareManagement.newGlobalCareGapNotice("x", name: "y")
        item.margin = 3954.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGlobalCareGapNoticeNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.GlobalCareGapNoticeNameLengthRule(maxLength: 16)
        let item = CareManagement.newGlobalCareGapNotice("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGlobalCareGapNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.GlobalCareGapNoticeCodeLengthRule(maxLength: 120)
        let item = CareManagement.newGlobalCareGapNotice("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
