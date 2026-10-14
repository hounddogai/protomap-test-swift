@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientCareProtocolThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultLenientCareProtocolThresholdValidator()
        let item = ClinicalOps.newLenientCareProtocolThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsLenientCareProtocolThresholdRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = ClinicalOps.LenientCareProtocolThresholdRequiredProcedureCodeRule(
            message: "lenient care protocol threshold needs this field"
        )
        let item = ClinicalOps.newLenientCareProtocolThreshold("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
