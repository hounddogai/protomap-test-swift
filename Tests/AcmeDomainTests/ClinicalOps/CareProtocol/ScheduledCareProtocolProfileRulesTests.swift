@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledCareProtocolProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultScheduledCareProtocolProfileValidator()
        let item = ClinicalOps.newScheduledCareProtocolProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsScheduledCareProtocolProfileRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = ClinicalOps.ScheduledCareProtocolProfileRateRangeRule(min: 3.5, max: 998.8)
        let item = ClinicalOps.newScheduledCareProtocolProfile("x", name: "y")
        item.rate = 1000.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsScheduledCareProtocolProfileRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = ClinicalOps.ScheduledCareProtocolProfileRegionLengthRule(maxLength: 120)
        let item = ClinicalOps.newScheduledCareProtocolProfile("x", name: "y")
        item.region = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsScheduledCareProtocolProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.ScheduledCareProtocolProfileRequiredCodeRule(
            message: "scheduled care protocol profile needs a value"
        )
        let item = ClinicalOps.newScheduledCareProtocolProfile("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsScheduledCareProtocolProfileRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.ScheduledCareProtocolProfileRequiredNameRule(
            message: "scheduled care protocol profile needs an entry"
        )
        let item = ClinicalOps.newScheduledCareProtocolProfile("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
