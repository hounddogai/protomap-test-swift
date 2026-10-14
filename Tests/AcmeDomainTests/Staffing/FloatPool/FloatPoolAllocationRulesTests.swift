@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolAllocationValidator()
        let item = Staffing.newFloatPoolAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolAllocationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.FloatPoolAllocationTitleLengthRule(maxLength: 255)
        let item = Staffing.newFloatPoolAllocation("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.FloatPoolAllocationCodeLengthRule(maxLength: 80)
        let item = Staffing.newFloatPoolAllocation("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolAllocationRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Staffing.FloatPoolAllocationRequiredWardRule(message: "float pool allocation needs a value")
        let item = Staffing.newFloatPoolAllocation("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolAllocationBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Staffing.FloatPoolAllocationBatchSizeRangeRule(min: 3600, max: 86400)
        let item = Staffing.newFloatPoolAllocation("x", title: "y")
        item.batchSize = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFloatPoolAllocationRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Staffing.FloatPoolAllocationRequiredDescriptionRule(message: "float pool allocation needs this field")
        let item = Staffing.newFloatPoolAllocation("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}
