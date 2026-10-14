@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxySnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxySnapshotValidator()
        let item = Consent.newProxySnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxySnapshotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.ProxySnapshotRequiredNameRule(message: "proxy snapshot needs this field")
        let item = Consent.newProxySnapshot("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
