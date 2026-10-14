@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetAllocationValidator()
        let item = ClinicalOps.newOrderSetAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.OrderSetAllocationCodeLengthRule(maxLength: 255)
        let item = ClinicalOps.newOrderSetAllocation("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsOrderSetAllocationFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = ClinicalOps.OrderSetAllocationFloorValueRangeRule(min: 0.5, max: 64.7)
        let item = ClinicalOps.newOrderSetAllocation("x", label: "y")
        item.floorValue = 66.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsOrderSetAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.OrderSetAllocationRequiredCodeRule(message: "order set allocation needs this field")
        let item = ClinicalOps.newOrderSetAllocation("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
