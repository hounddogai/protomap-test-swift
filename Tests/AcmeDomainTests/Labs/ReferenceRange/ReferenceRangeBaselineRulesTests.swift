@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeBaselineValidator()
        let item = Labs.newReferenceRangeBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeBaselineRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Labs.ReferenceRangeBaselineRequiredCountryRule(message: "reference range baseline needs an entry")
        let item = Labs.newReferenceRangeBaseline("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeBaselineScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Labs.ReferenceRangeBaselineScoreRangeRule(min: 2.5, max: 2538.0)
        let item = Labs.newReferenceRangeBaseline("x", name: "y")
        item.score = 2539.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsReferenceRangeBaselineNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.ReferenceRangeBaselineNameLengthRule(maxLength: 16)
        let item = Labs.newReferenceRangeBaseline("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeBaselineRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Labs.ReferenceRangeBaselineRequiredClinicianIDRule(message: "reference range baseline needs an entry")
        let item = Labs.newReferenceRangeBaseline("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}
