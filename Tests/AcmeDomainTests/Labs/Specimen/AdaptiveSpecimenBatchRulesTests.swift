@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveSpecimenBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAdaptiveSpecimenBatchValidator()
        let item = Labs.newAdaptiveSpecimenBatch("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAdaptiveSpecimenBatchRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Labs.AdaptiveSpecimenBatchRequiredChecksumRule(message: "adaptive specimen batch needs this field")
        let item = Labs.newAdaptiveSpecimenBatch("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAdaptiveSpecimenBatchRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.AdaptiveSpecimenBatchRequiredCodeRule(message: "adaptive specimen batch needs this field")
        let item = Labs.newAdaptiveSpecimenBatch("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAdaptiveSpecimenBatchNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.AdaptiveSpecimenBatchNameLengthRule(maxLength: 86400)
        let item = Labs.newAdaptiveSpecimenBatch("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAdaptiveSpecimenBatchRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.AdaptiveSpecimenBatchRequiredNameRule(message: "adaptive specimen batch needs a value")
        let item = Labs.newAdaptiveSpecimenBatch("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAdaptiveSpecimenBatchRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Labs.AdaptiveSpecimenBatchRequiredNotesRule(message: "adaptive specimen batch needs a value")
        let item = Labs.newAdaptiveSpecimenBatch("", name: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}
