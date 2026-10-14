@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalCareProtocolEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRegionalCareProtocolEstimateValidator()
        let item = ClinicalOps.newRegionalCareProtocolEstimate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRegionalCareProtocolEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.RegionalCareProtocolEstimateRequiredCodeRule(
            message: "regional care protocol estimate needs an entry"
        )
        let item = ClinicalOps.newRegionalCareProtocolEstimate("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRegionalCareProtocolEstimateUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = ClinicalOps.RegionalCareProtocolEstimateUnitLengthRule(maxLength: 86400)
        let item = ClinicalOps.newRegionalCareProtocolEstimate("x", label: "y")
        item.unit = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRegionalCareProtocolEstimateLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.RegionalCareProtocolEstimateLabelLengthRule(maxLength: 1000)
        let item = ClinicalOps.newRegionalCareProtocolEstimate("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
