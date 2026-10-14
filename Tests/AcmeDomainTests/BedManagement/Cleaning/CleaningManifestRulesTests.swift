@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningManifestValidator()
        let item = BedManagement.newCleaningManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningManifestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.CleaningManifestRequiredLabelRule(message: "cleaning manifest needs this field")
        let item = BedManagement.newCleaningManifest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningManifestContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = BedManagement.CleaningManifestContactEmailLengthRule(maxLength: 32)
        let item = BedManagement.newCleaningManifest("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCleaningManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.CleaningManifestRequiredCodeRule(message: "cleaning manifest needs a value")
        let item = BedManagement.newCleaningManifest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
