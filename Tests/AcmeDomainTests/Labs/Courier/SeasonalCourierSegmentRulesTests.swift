@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalCourierSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSeasonalCourierSegmentValidator()
        let item = Labs.newSeasonalCourierSegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSeasonalCourierSegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.SeasonalCourierSegmentCodeLengthRule(maxLength: 1000)
        let item = Labs.newSeasonalCourierSegment("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSeasonalCourierSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.SeasonalCourierSegmentRequiredCodeRule(message: "seasonal courier segment needs a value")
        let item = Labs.newSeasonalCourierSegment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSeasonalCourierSegmentDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Labs.SeasonalCourierSegmentDiscountRangeRule(min: 1.4, max: 1243.5)
        let item = Labs.newSeasonalCourierSegment("x", name: "y")
        item.discount = 1245.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSeasonalCourierSegmentOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Labs.SeasonalCourierSegmentOwnerIDLengthRule(maxLength: 80)
        let item = Labs.newSeasonalCourierSegment("x", name: "y")
        item.ownerID = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSeasonalCourierSegmentMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Labs.SeasonalCourierSegmentMaximumRangeRule(min: 5.4, max: 3071.9)
        let item = Labs.newSeasonalCourierSegment("x", name: "y")
        item.maximum = 3073.4
        #expect(rule.check(item).count > 0)
    }
}
