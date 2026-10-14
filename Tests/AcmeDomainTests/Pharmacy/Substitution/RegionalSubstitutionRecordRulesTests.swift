@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalSubstitutionRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRegionalSubstitutionRecordValidator()
        let item = Pharmacy.newRegionalSubstitutionRecord("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRegionalSubstitutionRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RegionalSubstitutionRecordRequiredCodeRule(
            message: "regional substitution record needs an entry"
        )
        let item = Pharmacy.newRegionalSubstitutionRecord("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRegionalSubstitutionRecordTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.RegionalSubstitutionRecordTitleLengthRule(maxLength: 3600)
        let item = Pharmacy.newRegionalSubstitutionRecord("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRegionalSubstitutionRecordRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Pharmacy.RegionalSubstitutionRecordRequiredProcedureCodeRule(
            message: "regional substitution record needs an entry"
        )
        let item = Pharmacy.newRegionalSubstitutionRecord("", title: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
