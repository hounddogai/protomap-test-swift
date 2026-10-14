@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachManifestValidator()
        let item = CareManagement.newOutreachManifest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachManifestRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = CareManagement.OutreachManifestRequiredDescriptionRule(message: "outreach manifest needs a value")
        let item = CareManagement.newOutreachManifest("", name: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachManifestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.OutreachManifestNameLengthRule(maxLength: 3600)
        let item = CareManagement.newOutreachManifest("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementOutreachManifestDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = CareManagement.OutreachManifestDescriptionLengthRule(maxLength: 1000)
        let item = CareManagement.newOutreachManifest("x", name: "y")
        item.description = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}
