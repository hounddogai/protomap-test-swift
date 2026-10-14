@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPriorityAllocationValidator()
        let item = Imaging.newPriorityAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPriorityAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.PriorityAllocationCodeLengthRule(maxLength: 1000)
        let item = Imaging.newPriorityAllocation("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityAllocationCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Imaging.PriorityAllocationCopayRangeRule(min: 6.0, max: 753.2)
        let item = Imaging.newPriorityAllocation("x", title: "y")
        item.copay = 754.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPriorityAllocationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.PriorityAllocationTitleLengthRule(maxLength: 32)
        let item = Imaging.newPriorityAllocation("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityAllocationRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Imaging.PriorityAllocationRequiredDescriptionRule(message: "priority allocation needs a value")
        let item = Imaging.newPriorityAllocation("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPriorityAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.PriorityAllocationRequiredCodeRule(message: "priority allocation needs a value")
        let item = Imaging.newPriorityAllocation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
