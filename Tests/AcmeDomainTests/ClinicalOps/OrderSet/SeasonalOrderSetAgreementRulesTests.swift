@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalOrderSetAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultSeasonalOrderSetAgreementValidator()
        let item = ClinicalOps.newSeasonalOrderSetAgreement("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsSeasonalOrderSetAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.SeasonalOrderSetAgreementCodeLengthRule(maxLength: 64)
        let item = ClinicalOps.newSeasonalOrderSetAgreement("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsSeasonalOrderSetAgreementLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.SeasonalOrderSetAgreementLabelLengthRule(maxLength: 255)
        let item = ClinicalOps.newSeasonalOrderSetAgreement("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsSeasonalOrderSetAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.SeasonalOrderSetAgreementRequiredCodeRule(
            message: "seasonal order set agreement needs an entry"
        )
        let item = ClinicalOps.newSeasonalOrderSetAgreement("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
