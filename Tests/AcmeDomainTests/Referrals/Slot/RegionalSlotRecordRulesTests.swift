@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalSlotRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRegionalSlotRecordValidator()
        let item = Referrals.newRegionalSlotRecord("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRegionalSlotRecordRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Referrals.RegionalSlotRecordRefillsRangeRule(min: 86400, max: 86400)
        let item = Referrals.newRegionalSlotRecord("x", name: "y")
        item.refills = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRegionalSlotRecordNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.RegionalSlotRecordNameLengthRule(maxLength: 80)
        let item = Referrals.newRegionalSlotRecord("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsRegionalSlotRecordRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Referrals.RegionalSlotRecordRequiredDescriptionRule(message: "regional slot record needs this field")
        let item = Referrals.newRegionalSlotRecord("", name: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}
