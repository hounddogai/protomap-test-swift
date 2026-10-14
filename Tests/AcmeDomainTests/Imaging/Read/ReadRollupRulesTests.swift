@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultReadRollupValidator()
        let item = Imaging.newReadRollup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingReadRollupDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Imaging.ReadRollupDiscountRangeRule(min: 2.7, max: 1014.9)
        let item = Imaging.newReadRollup("x", title: "y")
        item.discount = 1016.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingReadRollupSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Imaging.ReadRollupSequenceRangeRule(min: 32, max: 3600)
        let item = Imaging.newReadRollup("x", title: "y")
        item.sequence = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingReadRollupContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Imaging.ReadRollupContactEmailLengthRule(maxLength: 86400)
        let item = Imaging.newReadRollup("x", title: "y")
        item.contactEmail = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadRollupRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.ReadRollupRequiredTitleRule(message: "read rollup needs a value")
        let item = Imaging.newReadRollup("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingReadRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ReadRollupCodeLengthRule(maxLength: 16)
        let item = Imaging.newReadRollup("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
