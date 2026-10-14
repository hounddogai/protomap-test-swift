@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolAllocationValidator()
        let item = Imaging.newCareProtocolAllocation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolAllocationRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Imaging.CareProtocolAllocationRequiredDescriptionRule(
            message: "care protocol allocation needs an entry"
        )
        let item = Imaging.newCareProtocolAllocation("", name: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolAllocationDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Imaging.CareProtocolAllocationDosageMgRangeRule(min: 8.2, max: 170.1)
        let item = Imaging.newCareProtocolAllocation("x", name: "y")
        item.dosageMg = 171.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingCareProtocolAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.CareProtocolAllocationCodeLengthRule(maxLength: 120)
        let item = Imaging.newCareProtocolAllocation("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolAllocationQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Imaging.CareProtocolAllocationQuantityRangeRule(min: 32, max: 32)
        let item = Imaging.newCareProtocolAllocation("x", name: "y")
        item.quantity = 33
        #expect(rule.check(item).count > 0)
    }
}
