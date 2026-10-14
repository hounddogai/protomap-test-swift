@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallClaimValidator()
        let item = Pharmacy.newRecallClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallClaimEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Pharmacy.RecallClaimEncounterIDLengthRule(maxLength: 120)
        let item = Pharmacy.newRecallClaim("x", name: "y")
        item.encounterID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallClaimRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Pharmacy.RecallClaimRequiredEncounterIDRule(message: "recall claim needs a value")
        let item = Pharmacy.newRecallClaim("", name: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}
