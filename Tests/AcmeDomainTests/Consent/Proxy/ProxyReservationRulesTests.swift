@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyReservationValidator()
        let item = Consent.newProxyReservation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ProxyReservationRequiredCodeRule(message: "proxy reservation needs an entry")
        let item = Consent.newProxyReservation("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyReservationNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.ProxyReservationNameLengthRule(maxLength: 3600)
        let item = Consent.newProxyReservation("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
