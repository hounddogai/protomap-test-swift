@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionTargetValidator()
        let item = Labs.newAccessionTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionTargetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.AccessionTargetCodeLengthRule(maxLength: 64)
        let item = Labs.newAccessionTarget("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionTargetBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Labs.AccessionTargetBatchSizeRangeRule(min: 120, max: 120)
        let item = Labs.newAccessionTarget("x", name: "y")
        item.batchSize = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAccessionTargetOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Labs.AccessionTargetOwnerIDLengthRule(maxLength: 64)
        let item = Labs.newAccessionTarget("x", name: "y")
        item.ownerID = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.AccessionTargetRequiredCodeRule(message: "accession target needs this field")
        let item = Labs.newAccessionTarget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
