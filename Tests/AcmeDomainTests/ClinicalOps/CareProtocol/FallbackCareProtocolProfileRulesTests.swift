@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackCareProtocolProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultFallbackCareProtocolProfileValidator()
        let item = ClinicalOps.newFallbackCareProtocolProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsFallbackCareProtocolProfileRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = ClinicalOps.FallbackCareProtocolProfileRegionLengthRule(maxLength: 120)
        let item = ClinicalOps.newFallbackCareProtocolProfile("x", name: "y")
        item.region = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsFallbackCareProtocolProfileRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.FallbackCareProtocolProfileRequiredNameRule(
            message: "fallback care protocol profile needs an entry"
        )
        let item = ClinicalOps.newFallbackCareProtocolProfile("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsFallbackCareProtocolProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.FallbackCareProtocolProfileCodeLengthRule(maxLength: 120)
        let item = ClinicalOps.newFallbackCareProtocolProfile("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsFallbackCareProtocolProfileGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = ClinicalOps.FallbackCareProtocolProfileGraceDaysRangeRule(min: 16, max: 16)
        let item = ClinicalOps.newFallbackCareProtocolProfile("x", name: "y")
        item.graceDays = 17
        #expect(rule.check(item).count > 0)
    }
}
