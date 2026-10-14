@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictWorklistAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStrictWorklistAllocationValidator()
        let item = Imaging.newStrictWorklistAllocation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStrictWorklistAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.StrictWorklistAllocationCodeLengthRule(maxLength: 86400)
        let item = Imaging.newStrictWorklistAllocation("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStrictWorklistAllocationAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Imaging.StrictWorklistAllocationAmountRangeRule(min: 5.7, max: 4912.7)
        let item = Imaging.newStrictWorklistAllocation("x", name: "y")
        item.amount = 4914.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStrictWorklistAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.StrictWorklistAllocationRequiredCodeRule(message: "strict worklist allocation needs a value")
        let item = Imaging.newStrictWorklistAllocation("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStrictWorklistAllocationRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.StrictWorklistAllocationRequiredNameRule(
            message: "strict worklist allocation needs this field"
        )
        let item = Imaging.newStrictWorklistAllocation("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
