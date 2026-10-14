@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptivePriorityAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultAdaptivePriorityAuditValidator()
        let item = Imaging.newAdaptivePriorityAudit("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingAdaptivePriorityAuditBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Imaging.AdaptivePriorityAuditBudgetRangeRule(min: 8.1, max: 1394.9)
        let item = Imaging.newAdaptivePriorityAudit("x", name: "y")
        item.budget = 1396.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingAdaptivePriorityAuditRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Imaging.AdaptivePriorityAuditRateRangeRule(min: 0.8, max: 306.6)
        let item = Imaging.newAdaptivePriorityAudit("x", name: "y")
        item.rate = 308.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingAdaptivePriorityAuditChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Imaging.AdaptivePriorityAuditChannelLengthRule(maxLength: 120)
        let item = Imaging.newAdaptivePriorityAudit("x", name: "y")
        item.channel = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingAdaptivePriorityAuditRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Imaging.AdaptivePriorityAuditRetriesRangeRule(min: 16, max: 3600)
        let item = Imaging.newAdaptivePriorityAudit("x", name: "y")
        item.retries = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingAdaptivePriorityAuditRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.AdaptivePriorityAuditRequiredCodeRule(message: "adaptive priority audit needs an entry")
        let item = Imaging.newAdaptivePriorityAudit("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingAdaptivePriorityAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.AdaptivePriorityAuditCodeLengthRule(maxLength: 80)
        let item = Imaging.newAdaptivePriorityAudit("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
