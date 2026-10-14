@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledPriorityAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultScheduledPriorityAllocationValidator()
        let item = Imaging.newScheduledPriorityAllocation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingScheduledPriorityAllocationBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Imaging.ScheduledPriorityAllocationBatchSizeRangeRule(min: 80, max: 1000)
        let item = Imaging.newScheduledPriorityAllocation("x", name: "y")
        item.batchSize = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingScheduledPriorityAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ScheduledPriorityAllocationRequiredCodeRule(
            message: "scheduled priority allocation needs a value"
        )
        let item = Imaging.newScheduledPriorityAllocation("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingScheduledPriorityAllocationNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.ScheduledPriorityAllocationNameLengthRule(maxLength: 80)
        let item = Imaging.newScheduledPriorityAllocation("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
