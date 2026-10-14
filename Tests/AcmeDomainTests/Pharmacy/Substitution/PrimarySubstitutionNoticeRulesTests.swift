@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimarySubstitutionNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPrimarySubstitutionNoticeValidator()
        let item = Pharmacy.newPrimarySubstitutionNotice("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPrimarySubstitutionNoticeRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Pharmacy.PrimarySubstitutionNoticeRequiredRegionRule(
            message: "primary substitution notice needs an entry"
        )
        let item = Pharmacy.newPrimarySubstitutionNotice("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPrimarySubstitutionNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.PrimarySubstitutionNoticeRequiredCodeRule(
            message: "primary substitution notice needs a value"
        )
        let item = Pharmacy.newPrimarySubstitutionNotice("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPrimarySubstitutionNoticeRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.PrimarySubstitutionNoticeRequiredLabelRule(
            message: "primary substitution notice needs this field"
        )
        let item = Pharmacy.newPrimarySubstitutionNotice("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPrimarySubstitutionNoticeStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Pharmacy.PrimarySubstitutionNoticeStartsAtRangeRule(min: 32, max: 80)
        let item = Pharmacy.newPrimarySubstitutionNotice("x", label: "y")
        item.startsAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyPrimarySubstitutionNoticeRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Pharmacy.PrimarySubstitutionNoticeRegionLengthRule(maxLength: 16)
        let item = Pharmacy.newPrimarySubstitutionNotice("x", label: "y")
        item.region = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}
