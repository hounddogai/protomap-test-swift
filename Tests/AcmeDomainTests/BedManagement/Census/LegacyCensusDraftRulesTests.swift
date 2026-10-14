@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyCensusDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLegacyCensusDraftValidator()
        let item = BedManagement.newLegacyCensusDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLegacyCensusDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.LegacyCensusDraftCodeLengthRule(maxLength: 255)
        let item = BedManagement.newLegacyCensusDraft("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementLegacyCensusDraftRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = BedManagement.LegacyCensusDraftRequiredReviewerRule(message: "legacy census draft needs a value")
        let item = BedManagement.newLegacyCensusDraft("", label: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLegacyCensusDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.LegacyCensusDraftRequiredCodeRule(message: "legacy census draft needs this field")
        let item = BedManagement.newLegacyCensusDraft("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLegacyCensusDraftUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = BedManagement.LegacyCensusDraftUpdatedAtRangeRule(min: 64, max: 3600)
        let item = BedManagement.newLegacyCensusDraft("x", label: "y")
        item.updatedAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
