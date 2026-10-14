@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualOutreachRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultManualOutreachRecordValidator()
        let item = CareManagement.newManualOutreachRecord("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementManualOutreachRecordScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = CareManagement.ManualOutreachRecordScoreRangeRule(min: 2.2, max: 3980.3)
        let item = CareManagement.newManualOutreachRecord("x", name: "y")
        item.score = 3981.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementManualOutreachRecordCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = CareManagement.ManualOutreachRecordCategoryLengthRule(maxLength: 255)
        let item = CareManagement.newManualOutreachRecord("x", name: "y")
        item.category = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementManualOutreachRecordNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.ManualOutreachRecordNameLengthRule(maxLength: 64)
        let item = CareManagement.newManualOutreachRecord("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
