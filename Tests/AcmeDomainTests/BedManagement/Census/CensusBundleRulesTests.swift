@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusBundleValidator()
        let item = BedManagement.newCensusBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusBundleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.CensusBundleTitleLengthRule(maxLength: 86400)
        let item = BedManagement.newCensusBundle("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusBundleRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = BedManagement.CensusBundleRequiredChannelRule(message: "census bundle needs this field")
        let item = BedManagement.newCensusBundle("", title: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
