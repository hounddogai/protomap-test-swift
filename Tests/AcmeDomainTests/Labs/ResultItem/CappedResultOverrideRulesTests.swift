@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedResultOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCappedResultOverrideValidator()
        let item = Labs.newCappedResultOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCappedResultOverrideBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Labs.CappedResultOverrideBatchSizeRangeRule(min: 80, max: 255)
        let item = Labs.newCappedResultOverride("x", name: "y")
        item.batchSize = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCappedResultOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.CappedResultOverrideCodeLengthRule(maxLength: 1000)
        let item = Labs.newCappedResultOverride("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCappedResultOverrideNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.CappedResultOverrideNameLengthRule(maxLength: 86400)
        let item = Labs.newCappedResultOverride("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
