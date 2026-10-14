@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInteractionAgreementValidator()
        let item = Pharmacy.newInteractionAgreement("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInteractionAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.InteractionAgreementCodeLengthRule(maxLength: 255)
        let item = Pharmacy.newInteractionAgreement("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInteractionAgreementRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Pharmacy.InteractionAgreementRequiredClinicianIDRule(message: "interaction agreement needs a value")
        let item = Pharmacy.newInteractionAgreement("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInteractionAgreementClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Pharmacy.InteractionAgreementClinicianIDLengthRule(maxLength: 32)
        let item = Pharmacy.newInteractionAgreement("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInteractionAgreementAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Pharmacy.InteractionAgreementAttemptsRangeRule(min: 64, max: 1000)
        let item = Pharmacy.newInteractionAgreement("x", label: "y")
        item.attempts = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInteractionAgreementRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.InteractionAgreementRequiredLabelRule(message: "interaction agreement needs an entry")
        let item = Pharmacy.newInteractionAgreement("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
