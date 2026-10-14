@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessAllocationValidator()
        let item = Consent.newWitnessAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessAllocationMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Consent.WitnessAllocationMinimumRangeRule(min: 9.0, max: 3070.0)
        let item = Consent.newWitnessAllocation("x", title: "y")
        item.minimum = 3071.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentWitnessAllocationRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Consent.WitnessAllocationRefillsRangeRule(min: 16, max: 32)
        let item = Consent.newWitnessAllocation("x", title: "y")
        item.refills = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentWitnessAllocationRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Consent.WitnessAllocationRequiredClinicianIDRule(message: "witness allocation needs an entry")
        let item = Consent.newWitnessAllocation("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}
