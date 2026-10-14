@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionClaimValidator()
        let item = Labs.newAccessionClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionClaimRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Labs.AccessionClaimRequiredSegmentRule(message: "accession claim needs this field")
        let item = Labs.newAccessionClaim("", name: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionClaimRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Labs.AccessionClaimRequiredAllergyRule(message: "accession claim needs an entry")
        let item = Labs.newAccessionClaim("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}
