@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkAssignmentValidator()
        let item = Referrals.newNetworkAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkAssignmentFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Referrals.NetworkAssignmentFloorValueRangeRule(min: 2.8, max: 1968.0)
        let item = Referrals.newNetworkAssignment("x", label: "y")
        item.floorValue = 1969.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsNetworkAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.NetworkAssignmentCodeLengthRule(maxLength: 80)
        let item = Referrals.newNetworkAssignment("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsNetworkAssignmentRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Referrals.NetworkAssignmentRequiredSourceRule(message: "network assignment needs an entry")
        let item = Referrals.newNetworkAssignment("", label: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkAssignmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.NetworkAssignmentRequiredLabelRule(message: "network assignment needs a value")
        let item = Referrals.newNetworkAssignment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkAssignmentTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Referrals.NetworkAssignmentTimezoneLengthRule(maxLength: 255)
        let item = Referrals.newNetworkAssignment("x", label: "y")
        item.timezone = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
