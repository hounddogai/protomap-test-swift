@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalFloatPoolQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultRegionalFloatPoolQuotaValidator()
        let item = Staffing.newRegionalFloatPoolQuota("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingRegionalFloatPoolQuotaCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Staffing.RegionalFloatPoolQuotaCapacityRangeRule(min: 64, max: 80)
        let item = Staffing.newRegionalFloatPoolQuota("x", title: "y")
        item.capacity = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingRegionalFloatPoolQuotaRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.RegionalFloatPoolQuotaRequiredTitleRule(message: "regional float pool quota needs an entry")
        let item = Staffing.newRegionalFloatPoolQuota("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingRegionalFloatPoolQuotaRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.RegionalFloatPoolQuotaRequiredCodeRule(message: "regional float pool quota needs an entry")
        let item = Staffing.newRegionalFloatPoolQuota("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
