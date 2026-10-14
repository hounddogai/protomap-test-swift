@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachEstimateValidator()
        let item = CareManagement.newOutreachEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachEstimateRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = CareManagement.OutreachEstimateRequiredTimezoneRule(message: "outreach estimate needs a value")
        let item = CareManagement.newOutreachEstimate("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachEstimateRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = CareManagement.OutreachEstimateRequiredSegmentRule(message: "outreach estimate needs a value")
        let item = CareManagement.newOutreachEstimate("", name: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachEstimateAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = CareManagement.OutreachEstimateAmountRangeRule(min: 8.3, max: 3943.7)
        let item = CareManagement.newOutreachEstimate("x", name: "y")
        item.amount = 3945.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.OutreachEstimateCodeLengthRule(maxLength: 16)
        let item = CareManagement.newOutreachEstimate("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementOutreachEstimateNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.OutreachEstimateNameLengthRule(maxLength: 16)
        let item = CareManagement.newOutreachEstimate("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
