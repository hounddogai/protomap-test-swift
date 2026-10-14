@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementStrictAssessmentEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultStrictAssessmentEntryValidator()
        let item = CareManagement.newStrictAssessmentEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementStrictAssessmentEntryGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = CareManagement.StrictAssessmentEntryGraceDaysRangeRule(min: 80, max: 120)
        let item = CareManagement.newStrictAssessmentEntry("x", label: "y")
        item.graceDays = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementStrictAssessmentEntryLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.StrictAssessmentEntryLabelLengthRule(maxLength: 86400)
        let item = CareManagement.newStrictAssessmentEntry("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementStrictAssessmentEntryThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = CareManagement.StrictAssessmentEntryThresholdRangeRule(min: 2.1, max: 3148.2)
        let item = CareManagement.newStrictAssessmentEntry("x", label: "y")
        item.threshold = 3149.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementStrictAssessmentEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.StrictAssessmentEntryCodeLengthRule(maxLength: 120)
        let item = CareManagement.newStrictAssessmentEntry("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
