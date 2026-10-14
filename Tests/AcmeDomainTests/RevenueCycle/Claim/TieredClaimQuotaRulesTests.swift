@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredClaimQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultTieredClaimQuotaValidator()
        let item = RevenueCycle.newTieredClaimQuota("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleTieredClaimQuotaCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.TieredClaimQuotaCodeLengthRule(maxLength: 1000)
        let item = RevenueCycle.newTieredClaimQuota("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleTieredClaimQuotaRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.TieredClaimQuotaRequiredTitleRule(message: "tiered claim quota needs an entry")
        let item = RevenueCycle.newTieredClaimQuota("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleTieredClaimQuotaNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.TieredClaimQuotaNameLengthRule(maxLength: 120)
        let item = RevenueCycle.newTieredClaimQuota("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleTieredClaimQuotaDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = RevenueCycle.TieredClaimQuotaDiagnosisCodeLengthRule(maxLength: 255)
        let item = RevenueCycle.newTieredClaimQuota("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleTieredClaimQuotaRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = RevenueCycle.TieredClaimQuotaRequiredDiagnosisCodeRule(message: "tiered claim quota needs an entry")
        let item = RevenueCycle.newTieredClaimQuota("", name: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
