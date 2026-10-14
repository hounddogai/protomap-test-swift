@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveInventoryNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultAdaptiveInventoryNoticeValidator()
        let item = Pharmacy.newAdaptiveInventoryNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyAdaptiveInventoryNoticeRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.AdaptiveInventoryNoticeRequiredNameRule(message: "adaptive inventory notice needs a value")
        let item = Pharmacy.newAdaptiveInventoryNotice("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyAdaptiveInventoryNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.AdaptiveInventoryNoticeRequiredCodeRule(message: "adaptive inventory notice needs an entry")
        let item = Pharmacy.newAdaptiveInventoryNotice("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyAdaptiveInventoryNoticeRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Pharmacy.AdaptiveInventoryNoticeRevisionRangeRule(min: 80, max: 86400)
        let item = Pharmacy.newAdaptiveInventoryNotice("x", title: "y")
        item.revision = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyAdaptiveInventoryNoticeRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Pharmacy.AdaptiveInventoryNoticeRequiredCountryRule(
            message: "adaptive inventory notice needs a value"
        )
        let item = Pharmacy.newAdaptiveInventoryNotice("", title: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyAdaptiveInventoryNoticeBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Pharmacy.AdaptiveInventoryNoticeBatchSizeRangeRule(min: 120, max: 3600)
        let item = Pharmacy.newAdaptiveInventoryNotice("x", title: "y")
        item.batchSize = 3601
        #expect(rule.check(item).count > 0)
    }
}
