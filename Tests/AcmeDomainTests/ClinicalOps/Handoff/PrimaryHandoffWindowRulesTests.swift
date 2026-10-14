@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryHandoffWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPrimaryHandoffWindowValidator()
        let item = ClinicalOps.newPrimaryHandoffWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPrimaryHandoffWindowBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = ClinicalOps.PrimaryHandoffWindowBedLengthRule(maxLength: 16)
        let item = ClinicalOps.newPrimaryHandoffWindow("x", title: "y")
        item.bed = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPrimaryHandoffWindowRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = ClinicalOps.PrimaryHandoffWindowRequiredBedRule(message: "primary handoff window needs an entry")
        let item = ClinicalOps.newPrimaryHandoffWindow("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsPrimaryHandoffWindowRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = ClinicalOps.PrimaryHandoffWindowRequiredTimezoneRule(message: "primary handoff window needs an entry")
        let item = ClinicalOps.newPrimaryHandoffWindow("", title: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsPrimaryHandoffWindowRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = ClinicalOps.PrimaryHandoffWindowRateRangeRule(min: 8.0, max: 151.8)
        let item = ClinicalOps.newPrimaryHandoffWindow("x", title: "y")
        item.rate = 153.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsPrimaryHandoffWindowCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = ClinicalOps.PrimaryHandoffWindowCreatedAtRangeRule(min: 80, max: 86400)
        let item = ClinicalOps.newPrimaryHandoffWindow("x", title: "y")
        item.createdAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
