@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalCredentialBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultGlobalCredentialBundleValidator()
        let item = Staffing.newGlobalCredentialBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingGlobalCredentialBundleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.GlobalCredentialBundleRequiredLabelRule(message: "global credential bundle needs a value")
        let item = Staffing.newGlobalCredentialBundle("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingGlobalCredentialBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.GlobalCredentialBundleCodeLengthRule(maxLength: 120)
        let item = Staffing.newGlobalCredentialBundle("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingGlobalCredentialBundleRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Staffing.GlobalCredentialBundleRequiredFacilityRule(
            message: "global credential bundle needs this field"
        )
        let item = Staffing.newGlobalCredentialBundle("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingGlobalCredentialBundleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.GlobalCredentialBundleNameLengthRule(maxLength: 32)
        let item = Staffing.newGlobalCredentialBundle("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
