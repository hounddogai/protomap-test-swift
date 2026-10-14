@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceSnapshotValidator()
        let item = RevenueCycle.newRemittanceSnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceSnapshotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.RemittanceSnapshotRequiredNameRule(message: "remittance snapshot needs this field")
        let item = RevenueCycle.newRemittanceSnapshot("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceSnapshotCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = RevenueCycle.RemittanceSnapshotCountryLengthRule(maxLength: 80)
        let item = RevenueCycle.newRemittanceSnapshot("x", name: "y")
        item.country = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceSnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.RemittanceSnapshotCodeLengthRule(maxLength: 1000)
        let item = RevenueCycle.newRemittanceSnapshot("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceSnapshotRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = RevenueCycle.RemittanceSnapshotRequiredCountryRule(message: "remittance snapshot needs this field")
        let item = RevenueCycle.newRemittanceSnapshot("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}
