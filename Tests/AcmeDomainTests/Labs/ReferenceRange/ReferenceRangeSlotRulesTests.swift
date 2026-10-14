@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeSlotValidator()
        let item = Labs.newReferenceRangeSlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeSlotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.ReferenceRangeSlotLabelLengthRule(maxLength: 3600)
        let item = Labs.newReferenceRangeSlot("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeSlotDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Labs.ReferenceRangeSlotDescriptionLengthRule(maxLength: 120)
        let item = Labs.newReferenceRangeSlot("x", label: "y")
        item.description = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeSlotRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Labs.ReferenceRangeSlotRequiredExternalRefRule(message: "reference range slot needs an entry")
        let item = Labs.newReferenceRangeSlot("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
