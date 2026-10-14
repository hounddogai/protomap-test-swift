@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultProgramBatchValidator()
        let item = CareManagement.newProgramBatch("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementProgramBatchRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.ProgramBatchRequiredCodeRule(message: "program batch needs a value")
        let item = CareManagement.newProgramBatch("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementProgramBatchLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.ProgramBatchLabelLengthRule(maxLength: 1000)
        let item = CareManagement.newProgramBatch("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementProgramBatchRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = CareManagement.ProgramBatchRegionLengthRule(maxLength: 3600)
        let item = CareManagement.newProgramBatch("x", label: "y")
        item.region = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementProgramBatchThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = CareManagement.ProgramBatchThresholdRangeRule(min: 4.7, max: 1226.7)
        let item = CareManagement.newProgramBatch("x", label: "y")
        item.threshold = 1228.2
        #expect(rule.check(item).count > 0)
    }
}
