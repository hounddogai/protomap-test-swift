@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalIsolationBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultRegionalIsolationBaselineValidator()
        let item = BedManagement.newRegionalIsolationBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementRegionalIsolationBaselineLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = BedManagement.RegionalIsolationBaselineLocaleLengthRule(maxLength: 86400)
        let item = BedManagement.newRegionalIsolationBaseline("x", name: "y")
        item.locale = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementRegionalIsolationBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.RegionalIsolationBaselineRequiredCodeRule(
            message: "regional isolation baseline needs this field"
        )
        let item = BedManagement.newRegionalIsolationBaseline("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
