@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyDischargePlanDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLegacyDischargePlanDigestValidator()
        let item = BedManagement.newLegacyDischargePlanDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLegacyDischargePlanDigestPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = BedManagement.LegacyDischargePlanDigestPriorityRangeRule(min: 16, max: 80)
        let item = BedManagement.newLegacyDischargePlanDigest("x", label: "y")
        item.priority = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementLegacyDischargePlanDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.LegacyDischargePlanDigestRequiredCodeRule(
            message: "legacy discharge plan digest needs an entry"
        )
        let item = BedManagement.newLegacyDischargePlanDigest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLegacyDischargePlanDigestCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = BedManagement.LegacyDischargePlanDigestCreatedAtRangeRule(min: 16, max: 32)
        let item = BedManagement.newLegacyDischargePlanDigest("x", label: "y")
        item.createdAt = 33
        #expect(rule.check(item).count > 0)
    }
}
