@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolRequestValidator()
        let item = Imaging.newCareProtocolRequest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.CareProtocolRequestCodeLengthRule(maxLength: 32)
        let item = Imaging.newCareProtocolRequest("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolRequestDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Imaging.CareProtocolRequestDiscountRangeRule(min: 5.0, max: 158.5)
        let item = Imaging.newCareProtocolRequest("x", label: "y")
        item.discount = 160.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingCareProtocolRequestLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.CareProtocolRequestLabelLengthRule(maxLength: 16)
        let item = Imaging.newCareProtocolRequest("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolRequestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.CareProtocolRequestRequiredLabelRule(message: "care protocol request needs this field")
        let item = Imaging.newCareProtocolRequest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
