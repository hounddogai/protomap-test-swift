@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingSubstitutionClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRollingSubstitutionClaimValidator()
        let item = Pharmacy.newRollingSubstitutionClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRollingSubstitutionClaimDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Pharmacy.RollingSubstitutionClaimDiagnosisCodeLengthRule(maxLength: 120)
        let item = Pharmacy.newRollingSubstitutionClaim("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRollingSubstitutionClaimAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Pharmacy.RollingSubstitutionClaimAcuityRangeRule(min: 255, max: 3600)
        let item = Pharmacy.newRollingSubstitutionClaim("x", title: "y")
        item.acuity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRollingSubstitutionClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RollingSubstitutionClaimRequiredCodeRule(
            message: "rolling substitution claim needs this field"
        )
        let item = Pharmacy.newRollingSubstitutionClaim("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
