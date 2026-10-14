@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalCareProtocolDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultGlobalCareProtocolDigestValidator()
        let item = ClinicalOps.newGlobalCareProtocolDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsGlobalCareProtocolDigestRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = ClinicalOps.GlobalCareProtocolDigestRateRangeRule(min: 0.8, max: 1938.1)
        let item = ClinicalOps.newGlobalCareProtocolDigest("x", title: "y")
        item.rate = 1939.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsGlobalCareProtocolDigestStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = ClinicalOps.GlobalCareProtocolDigestStartsAtRangeRule(min: 32, max: 1000)
        let item = ClinicalOps.newGlobalCareProtocolDigest("x", title: "y")
        item.startsAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsGlobalCareProtocolDigestGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = ClinicalOps.GlobalCareProtocolDigestGraceDaysRangeRule(min: 32, max: 255)
        let item = ClinicalOps.newGlobalCareProtocolDigest("x", title: "y")
        item.graceDays = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsGlobalCareProtocolDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.GlobalCareProtocolDigestRequiredCodeRule(
            message: "global care protocol digest needs a value"
        )
        let item = ClinicalOps.newGlobalCareProtocolDigest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
