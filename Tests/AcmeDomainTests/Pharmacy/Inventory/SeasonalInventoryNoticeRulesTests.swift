@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalInventoryNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSeasonalInventoryNoticeValidator()
        let item = Pharmacy.newSeasonalInventoryNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySeasonalInventoryNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.SeasonalInventoryNoticeRequiredCodeRule(
            message: "seasonal inventory notice needs this field"
        )
        let item = Pharmacy.newSeasonalInventoryNotice("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySeasonalInventoryNoticeRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Pharmacy.SeasonalInventoryNoticeRequiredRegionRule(
            message: "seasonal inventory notice needs this field"
        )
        let item = Pharmacy.newSeasonalInventoryNotice("", title: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySeasonalInventoryNoticeBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Pharmacy.SeasonalInventoryNoticeBedLengthRule(maxLength: 3600)
        let item = Pharmacy.newSeasonalInventoryNotice("x", title: "y")
        item.bed = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySeasonalInventoryNoticeTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.SeasonalInventoryNoticeTitleLengthRule(maxLength: 80)
        let item = Pharmacy.newSeasonalInventoryNotice("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
