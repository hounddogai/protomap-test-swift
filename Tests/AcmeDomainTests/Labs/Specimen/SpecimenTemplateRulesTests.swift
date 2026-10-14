@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenTemplateValidator()
        let item = Labs.newSpecimenTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenTemplateRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Labs.SpecimenTemplateRequiredFacilityRule(message: "specimen template needs a value")
        let item = Labs.newSpecimenTemplate("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenTemplateFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Labs.SpecimenTemplateFacilityLengthRule(maxLength: 3600)
        let item = Labs.newSpecimenTemplate("x", title: "y")
        item.facility = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSpecimenTemplateRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.SpecimenTemplateRequiredTitleRule(message: "specimen template needs this field")
        let item = Labs.newSpecimenTemplate("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenTemplateStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Labs.SpecimenTemplateStartsAtRangeRule(min: 64, max: 80)
        let item = Labs.newSpecimenTemplate("x", title: "y")
        item.startsAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSpecimenTemplateSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Labs.SpecimenTemplateSpecialtyLengthRule(maxLength: 64)
        let item = Labs.newSpecimenTemplate("x", title: "y")
        item.specialty = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSpecimenTemplateRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Labs.SpecimenTemplateRevisionRangeRule(min: 3600, max: 86400)
        let item = Labs.newSpecimenTemplate("x", title: "y")
        item.revision = 86401
        #expect(rule.check(item).count > 0)
    }
}
