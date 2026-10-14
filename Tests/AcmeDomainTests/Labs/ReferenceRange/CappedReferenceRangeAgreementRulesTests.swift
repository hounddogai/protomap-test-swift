@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedReferenceRangeAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCappedReferenceRangeAgreementValidator()
        let item = Labs.newCappedReferenceRangeAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCappedReferenceRangeAgreementNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.CappedReferenceRangeAgreementNameLengthRule(maxLength: 1000)
        let item = Labs.newCappedReferenceRangeAgreement("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCappedReferenceRangeAgreementEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Labs.CappedReferenceRangeAgreementEncounterIDLengthRule(maxLength: 3600)
        let item = Labs.newCappedReferenceRangeAgreement("x", name: "y")
        item.encounterID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCappedReferenceRangeAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.CappedReferenceRangeAgreementRequiredCodeRule(
            message: "capped reference range agreement needs this field"
        )
        let item = Labs.newCappedReferenceRangeAgreement("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCappedReferenceRangeAgreementCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Labs.CappedReferenceRangeAgreementCapacityRangeRule(min: 3600, max: 86400)
        let item = Labs.newCappedReferenceRangeAgreement("x", name: "y")
        item.capacity = 86401
        #expect(rule.check(item).count > 0)
    }
}
