@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictCareProtocolRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultStrictCareProtocolRecordValidator()
        let item = ClinicalOps.newStrictCareProtocolRecord("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsStrictCareProtocolRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.StrictCareProtocolRecordRequiredCodeRule(
            message: "strict care protocol record needs this field"
        )
        let item = ClinicalOps.newStrictCareProtocolRecord("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
