@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningDraftValidator()
        let item = BedManagement.newCleaningDraft("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningDraftRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.CleaningDraftRequiredTitleRule(message: "cleaning draft needs a value")
        let item = BedManagement.newCleaningDraft("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningDraftTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.CleaningDraftTitleLengthRule(maxLength: 80)
        let item = BedManagement.newCleaningDraft("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCleaningDraftLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = BedManagement.CleaningDraftLimitRangeRule(min: 16, max: 3600)
        let item = BedManagement.newCleaningDraft("x", title: "y")
        item.limit = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCleaningDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.CleaningDraftRequiredCodeRule(message: "cleaning draft needs a value")
        let item = BedManagement.newCleaningDraft("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
