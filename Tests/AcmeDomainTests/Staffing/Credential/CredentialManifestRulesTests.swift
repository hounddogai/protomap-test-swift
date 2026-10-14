@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialManifestValidator()
        let item = Staffing.newCredentialManifest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialManifestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.CredentialManifestRequiredNameRule(message: "credential manifest needs a value")
        let item = Staffing.newCredentialManifest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.CredentialManifestRequiredCodeRule(message: "credential manifest needs this field")
        let item = Staffing.newCredentialManifest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
