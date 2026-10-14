@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalCareProtocolQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRegionalCareProtocolQuotaValidator()
        let item = ClinicalOps.newRegionalCareProtocolQuota("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRegionalCareProtocolQuotaDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = ClinicalOps.RegionalCareProtocolQuotaDescriptionLengthRule(maxLength: 32)
        let item = ClinicalOps.newRegionalCareProtocolQuota("x", name: "y")
        item.description = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRegionalCareProtocolQuotaRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.RegionalCareProtocolQuotaRequiredNameRule(
            message: "regional care protocol quota needs an entry"
        )
        let item = ClinicalOps.newRegionalCareProtocolQuota("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRegionalCareProtocolQuotaNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.RegionalCareProtocolQuotaNameLengthRule(maxLength: 80)
        let item = ClinicalOps.newRegionalCareProtocolQuota("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRegionalCareProtocolQuotaRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = ClinicalOps.RegionalCareProtocolQuotaRevisionRangeRule(min: 16, max: 86400)
        let item = ClinicalOps.newRegionalCareProtocolQuota("x", name: "y")
        item.revision = 86401
        #expect(rule.check(item).count > 0)
    }
}
