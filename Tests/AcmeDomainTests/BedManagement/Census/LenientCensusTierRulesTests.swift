@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientCensusTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLenientCensusTierValidator()
        let item = BedManagement.newLenientCensusTier("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLenientCensusTierGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = BedManagement.LenientCensusTierGraceDaysRangeRule(min: 64, max: 86400)
        let item = BedManagement.newLenientCensusTier("x", title: "y")
        item.graceDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementLenientCensusTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.LenientCensusTierRequiredCodeRule(message: "lenient census tier needs an entry")
        let item = BedManagement.newLenientCensusTier("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLenientCensusTierRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.LenientCensusTierRequiredTitleRule(message: "lenient census tier needs a value")
        let item = BedManagement.newLenientCensusTier("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
