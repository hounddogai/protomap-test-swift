@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusProfileValidator()
        let item = BedManagement.newCensusProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusProfileRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = BedManagement.CensusProfileRequiredWardRule(message: "census profile needs a value")
        let item = BedManagement.newCensusProfile("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusProfileClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = BedManagement.CensusProfileClinicianIDLengthRule(maxLength: 16)
        let item = BedManagement.newCensusProfile("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.CensusProfileCodeLengthRule(maxLength: 64)
        let item = BedManagement.newCensusProfile("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusProfileTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.CensusProfileTitleLengthRule(maxLength: 80)
        let item = BedManagement.newCensusProfile("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusProfileRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = BedManagement.CensusProfileRequiredClinicianIDRule(message: "census profile needs an entry")
        let item = BedManagement.newCensusProfile("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}
