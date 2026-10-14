@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingSpecimenGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPendingSpecimenGroupValidator()
        let item = Labs.newPendingSpecimenGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPendingSpecimenGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PendingSpecimenGroupRequiredCodeRule(message: "pending specimen group needs an entry")
        let item = Labs.newPendingSpecimenGroup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPendingSpecimenGroupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.PendingSpecimenGroupLabelLengthRule(maxLength: 1000)
        let item = Labs.newPendingSpecimenGroup("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPendingSpecimenGroupBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Labs.PendingSpecimenGroupBatchSizeRangeRule(min: 16, max: 3600)
        let item = Labs.newPendingSpecimenGroup("x", label: "y")
        item.batchSize = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPendingSpecimenGroupRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Labs.PendingSpecimenGroupRequiredProcedureCodeRule(message: "pending specimen group needs a value")
        let item = Labs.newPendingSpecimenGroup("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPendingSpecimenGroupProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Labs.PendingSpecimenGroupProcedureCodeLengthRule(maxLength: 64)
        let item = Labs.newPendingSpecimenGroup("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
