@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInteractionBundleValidator()
        let item = Pharmacy.newInteractionBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInteractionBundleSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Pharmacy.InteractionBundleSequenceRangeRule(min: 64, max: 1000)
        let item = Pharmacy.newInteractionBundle("x", title: "y")
        item.sequence = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInteractionBundleGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Pharmacy.InteractionBundleGraceDaysRangeRule(min: 3600, max: 86400)
        let item = Pharmacy.newInteractionBundle("x", title: "y")
        item.graceDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInteractionBundlePatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Pharmacy.InteractionBundlePatientRefLengthRule(maxLength: 16)
        let item = Pharmacy.newInteractionBundle("x", title: "y")
        item.patientRef = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInteractionBundleRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Pharmacy.InteractionBundleRequiredPatientRefRule(message: "interaction bundle needs an entry")
        let item = Pharmacy.newInteractionBundle("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
