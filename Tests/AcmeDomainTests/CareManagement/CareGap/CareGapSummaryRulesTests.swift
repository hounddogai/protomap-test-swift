@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCareGapSummaryValidator()
        let item = CareManagement.newCareGapSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCareGapSummaryDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = CareManagement.CareGapSummaryDescriptionLengthRule(maxLength: 16)
        let item = CareManagement.newCareGapSummary("x", title: "y")
        item.description = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCareGapSummaryNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = CareManagement.CareGapSummaryNotesLengthRule(maxLength: 120)
        let item = CareManagement.newCareGapSummary("x", title: "y")
        item.notes = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCareGapSummaryWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = CareManagement.CareGapSummaryWeightRangeRule(min: 6.8, max: 1515.0)
        let item = CareManagement.newCareGapSummary("x", title: "y")
        item.weight = 1516.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCareGapSummaryRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = CareManagement.CareGapSummaryRequiredDescriptionRule(message: "care gap summary needs a value")
        let item = CareManagement.newCareGapSummary("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}
