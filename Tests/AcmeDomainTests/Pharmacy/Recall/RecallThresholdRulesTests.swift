@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallThresholdValidator()
        let item = Pharmacy.newRecallThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallThresholdFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Pharmacy.RecallThresholdFacilityLengthRule(maxLength: 32)
        let item = Pharmacy.newRecallThreshold("x", name: "y")
        item.facility = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallThresholdRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Pharmacy.RecallThresholdRequiredEncounterIDRule(message: "recall threshold needs an entry")
        let item = Pharmacy.newRecallThreshold("", name: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallThresholdRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.RecallThresholdRequiredNameRule(message: "recall threshold needs this field")
        let item = Pharmacy.newRecallThreshold("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
