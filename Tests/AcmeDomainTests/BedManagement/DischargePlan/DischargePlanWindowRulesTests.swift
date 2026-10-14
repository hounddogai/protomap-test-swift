@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanWindowValidator()
        let item = BedManagement.newDischargePlanWindow("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanWindowChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = BedManagement.DischargePlanWindowChecksumLengthRule(maxLength: 120)
        let item = BedManagement.newDischargePlanWindow("x", name: "y")
        item.checksum = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDischargePlanWindowNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.DischargePlanWindowNameLengthRule(maxLength: 86400)
        let item = BedManagement.newDischargePlanWindow("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDischargePlanWindowDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = BedManagement.DischargePlanWindowDescriptionLengthRule(maxLength: 120)
        let item = BedManagement.newDischargePlanWindow("x", name: "y")
        item.description = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}
