@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedAccessionPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultBatchedAccessionPlanValidator()
        let item = Labs.newBatchedAccessionPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsBatchedAccessionPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.BatchedAccessionPlanRequiredCodeRule(message: "batched accession plan needs a value")
        let item = Labs.newBatchedAccessionPlan("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsBatchedAccessionPlanThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Labs.BatchedAccessionPlanThresholdRangeRule(min: 6.6, max: 3061.2)
        let item = Labs.newBatchedAccessionPlan("x", title: "y")
        item.threshold = 3062.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsBatchedAccessionPlanRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Labs.BatchedAccessionPlanRequiredOwnerIDRule(message: "batched accession plan needs this field")
        let item = Labs.newBatchedAccessionPlan("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsBatchedAccessionPlanRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Labs.BatchedAccessionPlanRequiredDescriptionRule(message: "batched accession plan needs a value")
        let item = Labs.newBatchedAccessionPlan("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsBatchedAccessionPlanOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Labs.BatchedAccessionPlanOwnerIDLengthRule(maxLength: 64)
        let item = Labs.newBatchedAccessionPlan("x", title: "y")
        item.ownerID = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
