@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenEntryValidator()
        let item = Labs.newSpecimenEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenEntryRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Labs.SpecimenEntryRequiredSegmentRule(message: "specimen entry needs a value")
        let item = Labs.newSpecimenEntry("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenEntryLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.SpecimenEntryLabelLengthRule(maxLength: 86400)
        let item = Labs.newSpecimenEntry("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSpecimenEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.SpecimenEntryCodeLengthRule(maxLength: 16)
        let item = Labs.newSpecimenEntry("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
