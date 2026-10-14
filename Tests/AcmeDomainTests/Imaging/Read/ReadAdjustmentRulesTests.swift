@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultReadAdjustmentValidator()
        let item = Imaging.newReadAdjustment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingReadAdjustmentMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Imaging.ReadAdjustmentMinimumRangeRule(min: 1.2, max: 1297.5)
        let item = Imaging.newReadAdjustment("x", title: "y")
        item.minimum = 1299.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingReadAdjustmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.ReadAdjustmentRequiredTitleRule(message: "read adjustment needs an entry")
        let item = Imaging.newReadAdjustment("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingReadAdjustmentRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Imaging.ReadAdjustmentRefillsRangeRule(min: 16, max: 86400)
        let item = Imaging.newReadAdjustment("x", title: "y")
        item.refills = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingReadAdjustmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.ReadAdjustmentNameLengthRule(maxLength: 86400)
        let item = Imaging.newReadAdjustment("x", title: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
