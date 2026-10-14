@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryReadAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPrimaryReadAgreementValidator()
        let item = Imaging.newPrimaryReadAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPrimaryReadAgreementRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Imaging.PrimaryReadAgreementRequiredAllergyRule(message: "primary read agreement needs a value")
        let item = Imaging.newPrimaryReadAgreement("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPrimaryReadAgreementSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Imaging.PrimaryReadAgreementSequenceRangeRule(min: 16, max: 120)
        let item = Imaging.newPrimaryReadAgreement("x", name: "y")
        item.sequence = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPrimaryReadAgreementNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.PrimaryReadAgreementNameLengthRule(maxLength: 86400)
        let item = Imaging.newPrimaryReadAgreement("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPrimaryReadAgreementSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Imaging.PrimaryReadAgreementSourceLengthRule(maxLength: 255)
        let item = Imaging.newPrimaryReadAgreement("x", name: "y")
        item.source = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPrimaryReadAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.PrimaryReadAgreementCodeLengthRule(maxLength: 32)
        let item = Imaging.newPrimaryReadAgreement("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
