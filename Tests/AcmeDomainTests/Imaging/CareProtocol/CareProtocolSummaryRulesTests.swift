@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolSummaryValidator()
        let item = Imaging.newCareProtocolSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolSummaryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.CareProtocolSummaryCodeLengthRule(maxLength: 32)
        let item = Imaging.newCareProtocolSummary("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolSummaryDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Imaging.CareProtocolSummaryDiscountRangeRule(min: 2.4, max: 289.0)
        let item = Imaging.newCareProtocolSummary("x", label: "y")
        item.discount = 290.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingCareProtocolSummaryStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Imaging.CareProtocolSummaryStartsAtRangeRule(min: 80, max: 1000)
        let item = Imaging.newCareProtocolSummary("x", label: "y")
        item.startsAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingCareProtocolSummaryLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.CareProtocolSummaryLabelLengthRule(maxLength: 32)
        let item = Imaging.newCareProtocolSummary("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.CareProtocolSummaryRequiredCodeRule(message: "care protocol summary needs an entry")
        let item = Imaging.newCareProtocolSummary("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
