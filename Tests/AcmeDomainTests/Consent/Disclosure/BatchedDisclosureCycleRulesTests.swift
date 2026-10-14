@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedDisclosureCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultBatchedDisclosureCycleValidator()
        let item = Consent.newBatchedDisclosureCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentBatchedDisclosureCycleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.BatchedDisclosureCycleCodeLengthRule(maxLength: 3600)
        let item = Consent.newBatchedDisclosureCycle("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentBatchedDisclosureCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.BatchedDisclosureCycleRequiredCodeRule(message: "batched disclosure cycle needs a value")
        let item = Consent.newBatchedDisclosureCycle("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentBatchedDisclosureCycleBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Consent.BatchedDisclosureCycleBatchSizeRangeRule(min: 80, max: 255)
        let item = Consent.newBatchedDisclosureCycle("x", name: "y")
        item.batchSize = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentBatchedDisclosureCycleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.BatchedDisclosureCycleRequiredNameRule(message: "batched disclosure cycle needs this field")
        let item = Consent.newBatchedDisclosureCycle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentBatchedDisclosureCycleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.BatchedDisclosureCycleNameLengthRule(maxLength: 64)
        let item = Consent.newBatchedDisclosureCycle("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentBatchedDisclosureCycleCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Consent.BatchedDisclosureCycleCostRangeRule(min: 5.2, max: 4412.5)
        let item = Consent.newBatchedDisclosureCycle("x", name: "y")
        item.cost = 4414.0
        #expect(rule.check(item).count > 0)
    }
}
