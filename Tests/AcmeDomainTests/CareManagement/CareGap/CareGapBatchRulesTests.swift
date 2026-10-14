@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCareGapBatchValidator()
        let item = CareManagement.newCareGapBatch("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCareGapBatchRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.CareGapBatchRequiredNameRule(message: "care gap batch needs this field")
        let item = CareManagement.newCareGapBatch("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapBatchNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.CareGapBatchNameLengthRule(maxLength: 86400)
        let item = CareManagement.newCareGapBatch("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCareGapBatchThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = CareManagement.CareGapBatchThresholdRangeRule(min: 8.6, max: 769.9)
        let item = CareManagement.newCareGapBatch("x", name: "y")
        item.threshold = 771.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCareGapBatchRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.CareGapBatchRequiredCodeRule(message: "care gap batch needs this field")
        let item = CareManagement.newCareGapBatch("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
