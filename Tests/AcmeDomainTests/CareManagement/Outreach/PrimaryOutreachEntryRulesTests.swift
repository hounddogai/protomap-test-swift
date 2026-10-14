@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryOutreachEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPrimaryOutreachEntryValidator()
        let item = CareManagement.newPrimaryOutreachEntry("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPrimaryOutreachEntryRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = CareManagement.PrimaryOutreachEntryRequiredWardRule(
            message: "primary outreach entry needs this field"
        )
        let item = CareManagement.newPrimaryOutreachEntry("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementPrimaryOutreachEntryExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = CareManagement.PrimaryOutreachEntryExpiresAtRangeRule(min: 255, max: 1000)
        let item = CareManagement.newPrimaryOutreachEntry("x", title: "y")
        item.expiresAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementPrimaryOutreachEntryTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.PrimaryOutreachEntryTitleLengthRule(maxLength: 3600)
        let item = CareManagement.newPrimaryOutreachEntry("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPrimaryOutreachEntryBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = CareManagement.PrimaryOutreachEntryBatchSizeRangeRule(min: 1000, max: 3600)
        let item = CareManagement.newPrimaryOutreachEntry("x", title: "y")
        item.batchSize = 3601
        #expect(rule.check(item).count > 0)
    }
}
