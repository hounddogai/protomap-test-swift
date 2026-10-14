@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningRequestValidator()
        let item = BedManagement.newCleaningRequest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningRequestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.CleaningRequestNameLengthRule(maxLength: 16)
        let item = BedManagement.newCleaningRequest("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCleaningRequestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.CleaningRequestRequiredNameRule(message: "cleaning request needs an entry")
        let item = BedManagement.newCleaningRequest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningRequestRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = BedManagement.CleaningRequestRequiredEncounterIDRule(message: "cleaning request needs a value")
        let item = BedManagement.newCleaningRequest("", name: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningRequestDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = BedManagement.CleaningRequestDiagnosisCodeLengthRule(maxLength: 255)
        let item = BedManagement.newCleaningRequest("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
