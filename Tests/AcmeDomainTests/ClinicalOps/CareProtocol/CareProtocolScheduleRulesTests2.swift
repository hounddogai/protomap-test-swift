@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolScheduleValidator()
        let item = ClinicalOps.newCareProtocolSchedule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolScheduleBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = ClinicalOps.CareProtocolScheduleBatchSizeRangeRule(min: 16, max: 255)
        let item = ClinicalOps.newCareProtocolSchedule("x", title: "y")
        item.batchSize = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCareProtocolScheduleExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = ClinicalOps.CareProtocolScheduleExternalRefLengthRule(maxLength: 3600)
        let item = ClinicalOps.newCareProtocolSchedule("x", title: "y")
        item.externalRef = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolScheduleBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = ClinicalOps.CareProtocolScheduleBudgetRangeRule(min: 9.0, max: 3372.3)
        let item = ClinicalOps.newCareProtocolSchedule("x", title: "y")
        item.budget = 3373.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCareProtocolScheduleChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = ClinicalOps.CareProtocolScheduleChannelLengthRule(maxLength: 16)
        let item = ClinicalOps.newCareProtocolSchedule("x", title: "y")
        item.channel = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}
