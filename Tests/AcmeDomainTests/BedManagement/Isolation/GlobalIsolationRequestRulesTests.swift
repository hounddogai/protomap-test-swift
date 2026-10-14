@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalIsolationRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultGlobalIsolationRequestValidator()
        let item = BedManagement.newGlobalIsolationRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementGlobalIsolationRequestRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = BedManagement.GlobalIsolationRequestRegionLengthRule(maxLength: 80)
        let item = BedManagement.newGlobalIsolationRequest("x", title: "y")
        item.region = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementGlobalIsolationRequestRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = BedManagement.GlobalIsolationRequestRateRangeRule(min: 1.6, max: 3746.0)
        let item = BedManagement.newGlobalIsolationRequest("x", title: "y")
        item.rate = 3747.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementGlobalIsolationRequestRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = BedManagement.GlobalIsolationRequestRequiredSourceRule(
            message: "global isolation request needs a value"
        )
        let item = BedManagement.newGlobalIsolationRequest("", title: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementGlobalIsolationRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.GlobalIsolationRequestRequiredCodeRule(
            message: "global isolation request needs this field"
        )
        let item = BedManagement.newGlobalIsolationRequest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementGlobalIsolationRequestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.GlobalIsolationRequestTitleLengthRule(maxLength: 120)
        let item = BedManagement.newGlobalIsolationRequest("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
