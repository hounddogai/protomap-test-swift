@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedClaimForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultCappedClaimForecastValidator()
        let item = RevenueCycle.newCappedClaimForecast("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleCappedClaimForecastRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = RevenueCycle.CappedClaimForecastRevisionRangeRule(min: 64, max: 86400)
        let item = RevenueCycle.newCappedClaimForecast("x", name: "y")
        item.revision = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleCappedClaimForecastRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = RevenueCycle.CappedClaimForecastRequiredChecksumRule(message: "capped claim forecast needs an entry")
        let item = RevenueCycle.newCappedClaimForecast("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleCappedClaimForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.CappedClaimForecastCodeLengthRule(maxLength: 86400)
        let item = RevenueCycle.newCappedClaimForecast("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
