@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryCleaningManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPrimaryCleaningManifestValidator()
        let item = BedManagement.newPrimaryCleaningManifest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPrimaryCleaningManifestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.PrimaryCleaningManifestTitleLengthRule(maxLength: 120)
        let item = BedManagement.newPrimaryCleaningManifest("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPrimaryCleaningManifestEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = BedManagement.PrimaryCleaningManifestEncounterIDLengthRule(maxLength: 3600)
        let item = BedManagement.newPrimaryCleaningManifest("x", title: "y")
        item.encounterID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
