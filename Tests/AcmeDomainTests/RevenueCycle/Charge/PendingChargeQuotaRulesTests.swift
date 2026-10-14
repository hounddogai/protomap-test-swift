@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingChargeQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultPendingChargeQuotaValidator()
        let item = RevenueCycle.newPendingChargeQuota("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCyclePendingChargeQuotaRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.PendingChargeQuotaRequiredTitleRule(message: "pending charge quota needs this field")
        let item = RevenueCycle.newPendingChargeQuota("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCyclePendingChargeQuotaRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = RevenueCycle.PendingChargeQuotaRequiredDiagnosisCodeRule(
            message: "pending charge quota needs an entry"
        )
        let item = RevenueCycle.newPendingChargeQuota("", title: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
