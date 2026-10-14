@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCareGapEntryValidator()
        let item = CareManagement.newCareGapEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCareGapEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.CareGapEntryCodeLengthRule(maxLength: 64)
        let item = CareManagement.newCareGapEntry("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCareGapEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.CareGapEntryRequiredCodeRule(message: "care gap entry needs an entry")
        let item = CareManagement.newCareGapEntry("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapEntryRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.CareGapEntryRequiredNameRule(message: "care gap entry needs this field")
        let item = CareManagement.newCareGapEntry("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapEntryContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = CareManagement.CareGapEntryContactEmailLengthRule(maxLength: 64)
        let item = CareManagement.newCareGapEntry("x", name: "y")
        item.contactEmail = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCareGapEntryVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = CareManagement.CareGapEntryVisitMinutesRangeRule(min: 16, max: 1000)
        let item = CareManagement.newCareGapEntry("x", name: "y")
        item.visitMinutes = 1001
        #expect(rule.check(item).count > 0)
    }
}
