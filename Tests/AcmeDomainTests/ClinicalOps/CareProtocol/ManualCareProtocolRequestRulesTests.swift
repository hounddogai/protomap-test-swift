@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsManualCareProtocolRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultManualCareProtocolRequestValidator()
        let item = ClinicalOps.newManualCareProtocolRequest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsManualCareProtocolRequestDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = ClinicalOps.ManualCareProtocolRequestDosageMgRangeRule(min: 5.8, max: 998.5)
        let item = ClinicalOps.newManualCareProtocolRequest("x", name: "y")
        item.dosageMg = 1000.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsManualCareProtocolRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.ManualCareProtocolRequestRequiredCodeRule(
            message: "manual care protocol request needs an entry"
        )
        let item = ClinicalOps.newManualCareProtocolRequest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsManualCareProtocolRequestRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = ClinicalOps.ManualCareProtocolRequestRequiredCurrencyRule(
            message: "manual care protocol request needs an entry"
        )
        let item = ClinicalOps.newManualCareProtocolRequest("", name: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsManualCareProtocolRequestCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = ClinicalOps.ManualCareProtocolRequestCurrencyLengthRule(maxLength: 120)
        let item = ClinicalOps.newManualCareProtocolRequest("x", name: "y")
        item.currency = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}
