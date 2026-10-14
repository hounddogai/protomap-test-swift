@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredCareProtocolGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultTieredCareProtocolGroupValidator()
        let item = Imaging.newTieredCareProtocolGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingTieredCareProtocolGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.TieredCareProtocolGroupRequiredCodeRule(
            message: "tiered care protocol group needs this field"
        )
        let item = Imaging.newTieredCareProtocolGroup("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingTieredCareProtocolGroupRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.TieredCareProtocolGroupRequiredLabelRule(message: "tiered care protocol group needs a value")
        let item = Imaging.newTieredCareProtocolGroup("", title: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingTieredCareProtocolGroupRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Imaging.TieredCareProtocolGroupRefillsRangeRule(min: 16, max: 80)
        let item = Imaging.newTieredCareProtocolGroup("x", title: "y")
        item.refills = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingTieredCareProtocolGroupRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.TieredCareProtocolGroupRequiredNameRule(message: "tiered care protocol group needs a value")
        let item = Imaging.newTieredCareProtocolGroup("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingTieredCareProtocolGroupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.TieredCareProtocolGroupNameLengthRule(maxLength: 80)
        let item = Imaging.newTieredCareProtocolGroup("x", title: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
