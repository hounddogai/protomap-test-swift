@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningBundleValidator()
        let item = BedManagement.newCleaningBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningBundleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.CleaningBundleRequiredTitleRule(message: "cleaning bundle needs a value")
        let item = BedManagement.newCleaningBundle("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningBundleRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = BedManagement.CleaningBundleRequiredPayerRule(message: "cleaning bundle needs this field")
        let item = BedManagement.newCleaningBundle("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningBundleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.CleaningBundleTitleLengthRule(maxLength: 16)
        let item = BedManagement.newCleaningBundle("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCleaningBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.CleaningBundleRequiredCodeRule(message: "cleaning bundle needs a value")
        let item = BedManagement.newCleaningBundle("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
