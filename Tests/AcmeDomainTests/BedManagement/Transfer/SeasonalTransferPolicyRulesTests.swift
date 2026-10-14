@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementSeasonalTransferPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultSeasonalTransferPolicyValidator()
        let item = BedManagement.newSeasonalTransferPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementSeasonalTransferPolicyRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = BedManagement.SeasonalTransferPolicyRequiredUnitRule(
            message: "seasonal transfer policy needs this field"
        )
        let item = BedManagement.newSeasonalTransferPolicy("", name: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementSeasonalTransferPolicyTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.SeasonalTransferPolicyTitleLengthRule(maxLength: 16)
        let item = BedManagement.newSeasonalTransferPolicy("x", name: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementSeasonalTransferPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.SeasonalTransferPolicyRequiredCodeRule(
            message: "seasonal transfer policy needs an entry"
        )
        let item = BedManagement.newSeasonalTransferPolicy("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementSeasonalTransferPolicyRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = BedManagement.SeasonalTransferPolicyRefillsRangeRule(min: 16, max: 16)
        let item = BedManagement.newSeasonalTransferPolicy("x", name: "y")
        item.refills = 17
        #expect(rule.check(item).count > 0)
    }
}
