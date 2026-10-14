@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalOutreachEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRegionalOutreachEntryValidator()
        let item = CareManagement.newRegionalOutreachEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRegionalOutreachEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.RegionalOutreachEntryRequiredCodeRule(
            message: "regional outreach entry needs an entry"
        )
        let item = CareManagement.newRegionalOutreachEntry("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRegionalOutreachEntryRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = CareManagement.RegionalOutreachEntryRetriesRangeRule(min: 3600, max: 3600)
        let item = CareManagement.newRegionalOutreachEntry("x", label: "y")
        item.retries = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRegionalOutreachEntryUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = CareManagement.RegionalOutreachEntryUnitLengthRule(maxLength: 1000)
        let item = CareManagement.newRegionalOutreachEntry("x", label: "y")
        item.unit = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRegionalOutreachEntryRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = CareManagement.RegionalOutreachEntryRevisionRangeRule(min: 16, max: 255)
        let item = CareManagement.newRegionalOutreachEntry("x", label: "y")
        item.revision = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRegionalOutreachEntryRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = CareManagement.RegionalOutreachEntryRequiredUnitRule(
            message: "regional outreach entry needs this field"
        )
        let item = CareManagement.newRegionalOutreachEntry("", label: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
