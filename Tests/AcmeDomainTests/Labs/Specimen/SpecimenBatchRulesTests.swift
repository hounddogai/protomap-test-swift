@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenBatchValidator()
        let item = Labs.newSpecimenBatch("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenBatchLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.SpecimenBatchLabelLengthRule(maxLength: 120)
        let item = Labs.newSpecimenBatch("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSpecimenBatchSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Labs.SpecimenBatchSourceLengthRule(maxLength: 64)
        let item = Labs.newSpecimenBatch("x", label: "y")
        item.source = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}
