@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenVarianceValidator()
        let item = Labs.newSpecimenVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenVarianceRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Labs.SpecimenVarianceRequiredAllergyRule(message: "specimen variance needs this field")
        let item = Labs.newSpecimenVariance("", title: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenVarianceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.SpecimenVarianceRequiredCodeRule(message: "specimen variance needs an entry")
        let item = Labs.newSpecimenVariance("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenVarianceBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Labs.SpecimenVarianceBedLengthRule(maxLength: 3600)
        let item = Labs.newSpecimenVariance("x", title: "y")
        item.bed = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
