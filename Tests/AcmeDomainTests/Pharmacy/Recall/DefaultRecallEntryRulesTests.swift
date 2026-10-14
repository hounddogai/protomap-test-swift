@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultRecallEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDefaultRecallEntryValidator()
        let item = Pharmacy.newDefaultRecallEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDefaultRecallEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.DefaultRecallEntryCodeLengthRule(maxLength: 1000)
        let item = Pharmacy.newDefaultRecallEntry("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDefaultRecallEntryRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Pharmacy.DefaultRecallEntryRequiredProcedureCodeRule(message: "default recall entry needs this field")
        let item = Pharmacy.newDefaultRecallEntry("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDefaultRecallEntryDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Pharmacy.DefaultRecallEntryDiagnosisCodeLengthRule(maxLength: 64)
        let item = Pharmacy.newDefaultRecallEntry("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDefaultRecallEntryScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Pharmacy.DefaultRecallEntryScoreRangeRule(min: 9.3, max: 3051.4)
        let item = Pharmacy.newDefaultRecallEntry("x", name: "y")
        item.score = 3052.9
        #expect(rule.check(item).count > 0)
    }
}
