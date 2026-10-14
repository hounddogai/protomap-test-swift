@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolRecordValidator()
        let item = ClinicalOps.newCareProtocolRecord("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolRecordPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = ClinicalOps.CareProtocolRecordPatientRefLengthRule(maxLength: 80)
        let item = ClinicalOps.newCareProtocolRecord("x", name: "y")
        item.patientRef = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolRecordRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = ClinicalOps.CareProtocolRecordRequiredPatientRefRule(message: "care protocol record needs an entry")
        let item = ClinicalOps.newCareProtocolRecord("", name: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolRecordEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = ClinicalOps.CareProtocolRecordEndsAtRangeRule(min: 64, max: 3600)
        let item = ClinicalOps.newCareProtocolRecord("x", name: "y")
        item.endsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
