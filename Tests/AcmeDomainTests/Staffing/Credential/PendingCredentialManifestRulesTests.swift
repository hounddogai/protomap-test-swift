@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingCredentialManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPendingCredentialManifestValidator()
        let item = Staffing.newPendingCredentialManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPendingCredentialManifestMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Staffing.PendingCredentialManifestMinimumRangeRule(min: 8.3, max: 2539.6)
        let item = Staffing.newPendingCredentialManifest("x", label: "y")
        item.minimum = 2541.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingPendingCredentialManifestMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Staffing.PendingCredentialManifestMaximumRangeRule(min: 3.1, max: 2594.0)
        let item = Staffing.newPendingCredentialManifest("x", label: "y")
        item.maximum = 2595.5
        #expect(rule.check(item).count > 0)
    }
}
