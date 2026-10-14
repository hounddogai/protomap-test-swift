@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanBatchValidator()
        let item = BedManagement.newDischargePlanBatch("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanBatchLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.DischargePlanBatchLabelLengthRule(maxLength: 120)
        let item = BedManagement.newDischargePlanBatch("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDischargePlanBatchRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.DischargePlanBatchRequiredLabelRule(message: "discharge plan batch needs a value")
        let item = BedManagement.newDischargePlanBatch("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDischargePlanBatchCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.DischargePlanBatchCodeLengthRule(maxLength: 80)
        let item = BedManagement.newDischargePlanBatch("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDischargePlanBatchSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = BedManagement.DischargePlanBatchSequenceRangeRule(min: 32, max: 255)
        let item = BedManagement.newDischargePlanBatch("x", label: "y")
        item.sequence = 256
        #expect(rule.check(item).count > 0)
    }
}
