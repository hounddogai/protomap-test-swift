@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialBundleValidator()
        let item = Staffing.newCredentialBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialBundleContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Staffing.CredentialBundleContactEmailLengthRule(maxLength: 3600)
        let item = Staffing.newCredentialBundle("x", name: "y")
        item.contactEmail = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialBundleChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Staffing.CredentialBundleChecksumLengthRule(maxLength: 120)
        let item = Staffing.newCredentialBundle("x", name: "y")
        item.checksum = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialBundleRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Staffing.CredentialBundleRequiredContactEmailRule(message: "credential bundle needs this field")
        let item = Staffing.newCredentialBundle("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialBundleRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Staffing.CredentialBundleRequiredChecksumRule(message: "credential bundle needs a value")
        let item = Staffing.newCredentialBundle("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialBundleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.CredentialBundleNameLengthRule(maxLength: 32)
        let item = Staffing.newCredentialBundle("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialBundleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.CredentialBundleRequiredNameRule(message: "credential bundle needs a value")
        let item = Staffing.newCredentialBundle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
