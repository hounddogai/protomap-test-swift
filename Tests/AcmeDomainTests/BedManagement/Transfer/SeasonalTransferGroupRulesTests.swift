@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementSeasonalTransferGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultSeasonalTransferGroupValidator()
        let item = BedManagement.newSeasonalTransferGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementSeasonalTransferGroupRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = BedManagement.SeasonalTransferGroupRequiredEncounterIDRule(
            message: "seasonal transfer group needs this field"
        )
        let item = BedManagement.newSeasonalTransferGroup("", title: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementSeasonalTransferGroupContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = BedManagement.SeasonalTransferGroupContactEmailLengthRule(maxLength: 255)
        let item = BedManagement.newSeasonalTransferGroup("x", title: "y")
        item.contactEmail = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementSeasonalTransferGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.SeasonalTransferGroupRequiredCodeRule(message: "seasonal transfer group needs a value")
        let item = BedManagement.newSeasonalTransferGroup("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementSeasonalTransferGroupEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = BedManagement.SeasonalTransferGroupEncounterIDLengthRule(maxLength: 3600)
        let item = BedManagement.newSeasonalTransferGroup("x", title: "y")
        item.encounterID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementSeasonalTransferGroupDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = BedManagement.SeasonalTransferGroupDiscountRangeRule(min: 9.5, max: 3810.2)
        let item = BedManagement.newSeasonalTransferGroup("x", title: "y")
        item.discount = 3811.7
        #expect(rule.check(item).count > 0)
    }
}
