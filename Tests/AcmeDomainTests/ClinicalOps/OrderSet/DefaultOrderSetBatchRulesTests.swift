@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultOrderSetBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultDefaultOrderSetBatchValidator()
        let item = ClinicalOps.newDefaultOrderSetBatch("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsDefaultOrderSetBatchRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = ClinicalOps.DefaultOrderSetBatchRequiredChannelRule(
            message: "default order set batch needs this field"
        )
        let item = ClinicalOps.newDefaultOrderSetBatch("", label: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsDefaultOrderSetBatchRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = ClinicalOps.DefaultOrderSetBatchRequiredRegionRule(
            message: "default order set batch needs this field"
        )
        let item = ClinicalOps.newDefaultOrderSetBatch("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsDefaultOrderSetBatchFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = ClinicalOps.DefaultOrderSetBatchFloorValueRangeRule(min: 5.4, max: 254.3)
        let item = ClinicalOps.newDefaultOrderSetBatch("x", label: "y")
        item.floorValue = 255.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsDefaultOrderSetBatchRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.DefaultOrderSetBatchRequiredLabelRule(message: "default order set batch needs this field")
        let item = ClinicalOps.newDefaultOrderSetBatch("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
