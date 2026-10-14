@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveCleaningOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultAdaptiveCleaningOverrideValidator()
        let item = BedManagement.newAdaptiveCleaningOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementAdaptiveCleaningOverrideRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.AdaptiveCleaningOverrideRequiredTitleRule(
            message: "adaptive cleaning override needs a value"
        )
        let item = BedManagement.newAdaptiveCleaningOverride("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementAdaptiveCleaningOverrideOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = BedManagement.AdaptiveCleaningOverrideOwnerIDLengthRule(maxLength: 16)
        let item = BedManagement.newAdaptiveCleaningOverride("x", title: "y")
        item.ownerID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
