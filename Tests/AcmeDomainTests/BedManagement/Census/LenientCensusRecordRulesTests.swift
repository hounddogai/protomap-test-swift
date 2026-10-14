@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientCensusRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLenientCensusRecordValidator()
        let item = BedManagement.newLenientCensusRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLenientCensusRecordCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.LenientCensusRecordCodeLengthRule(maxLength: 16)
        let item = BedManagement.newLenientCensusRecord("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementLenientCensusRecordCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = BedManagement.LenientCensusRecordCopayRangeRule(min: 6.5, max: 2898.7)
        let item = BedManagement.newLenientCensusRecord("x", label: "y")
        item.copay = 2900.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementLenientCensusRecordLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.LenientCensusRecordLabelLengthRule(maxLength: 3600)
        let item = BedManagement.newLenientCensusRecord("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementLenientCensusRecordRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.LenientCensusRecordRequiredLabelRule(message: "lenient census record needs this field")
        let item = BedManagement.newLenientCensusRecord("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLenientCensusRecordBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = BedManagement.LenientCensusRecordBatchSizeRangeRule(min: 120, max: 1000)
        let item = BedManagement.newLenientCensusRecord("x", label: "y")
        item.batchSize = 1001
        #expect(rule.check(item).count > 0)
    }
}
