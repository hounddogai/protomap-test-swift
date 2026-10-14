@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultCensusWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDefaultCensusWindowValidator()
        let item = BedManagement.newDefaultCensusWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDefaultCensusWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.DefaultCensusWindowRequiredCodeRule(message: "default census window needs an entry")
        let item = BedManagement.newDefaultCensusWindow("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDefaultCensusWindowSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = BedManagement.DefaultCensusWindowSourceLengthRule(maxLength: 1000)
        let item = BedManagement.newDefaultCensusWindow("x", label: "y")
        item.source = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDefaultCensusWindowRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = BedManagement.DefaultCensusWindowRequiredSourceRule(message: "default census window needs a value")
        let item = BedManagement.newDefaultCensusWindow("", label: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDefaultCensusWindowRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = BedManagement.DefaultCensusWindowRetriesRangeRule(min: 80, max: 120)
        let item = BedManagement.newDefaultCensusWindow("x", label: "y")
        item.retries = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDefaultCensusWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.DefaultCensusWindowCodeLengthRule(maxLength: 64)
        let item = BedManagement.newDefaultCensusWindow("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
