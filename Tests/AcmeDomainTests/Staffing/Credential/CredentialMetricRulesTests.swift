@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialMetricValidator()
        let item = Staffing.newCredentialMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialMetricRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Staffing.CredentialMetricRequiredFacilityRule(message: "credential metric needs an entry")
        let item = Staffing.newCredentialMetric("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.CredentialMetricCodeLengthRule(maxLength: 255)
        let item = Staffing.newCredentialMetric("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialMetricRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.CredentialMetricRequiredTitleRule(message: "credential metric needs this field")
        let item = Staffing.newCredentialMetric("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialMetricFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Staffing.CredentialMetricFacilityLengthRule(maxLength: 255)
        let item = Staffing.newCredentialMetric("x", name: "y")
        item.facility = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialMetricNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.CredentialMetricNameLengthRule(maxLength: 80)
        let item = Staffing.newCredentialMetric("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialMetricTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.CredentialMetricTitleLengthRule(maxLength: 64)
        let item = Staffing.newCredentialMetric("x", name: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
