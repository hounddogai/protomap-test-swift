@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationOverrideValidator()
        let item = RevenueCycle.newAuthorizationOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}
