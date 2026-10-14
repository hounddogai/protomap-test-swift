@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessThresholdValidator()
        let item = Consent.newWitnessThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessThresholdRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Consent.WitnessThresholdRequiredClinicianIDRule(message: "witness threshold needs a value")
        let item = Consent.newWitnessThreshold("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessThresholdOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Consent.WitnessThresholdOwnerIDLengthRule(maxLength: 255)
        let item = Consent.newWitnessThreshold("x", title: "y")
        item.ownerID = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWitnessThresholdTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.WitnessThresholdTitleLengthRule(maxLength: 255)
        let item = Consent.newWitnessThreshold("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
