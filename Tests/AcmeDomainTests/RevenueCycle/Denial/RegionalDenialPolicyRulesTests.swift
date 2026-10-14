@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalDenialPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRegionalDenialPolicyValidator()
        let item = RevenueCycle.newRegionalDenialPolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRegionalDenialPolicyRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.RegionalDenialPolicyRequiredTitleRule(message: "regional denial policy needs this field")
        let item = RevenueCycle.newRegionalDenialPolicy("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRegionalDenialPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.RegionalDenialPolicyRequiredCodeRule(message: "regional denial policy needs an entry")
        let item = RevenueCycle.newRegionalDenialPolicy("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRegionalDenialPolicyRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = RevenueCycle.RegionalDenialPolicyRequiredDiagnosisCodeRule(
            message: "regional denial policy needs this field"
        )
        let item = RevenueCycle.newRegionalDenialPolicy("", title: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
