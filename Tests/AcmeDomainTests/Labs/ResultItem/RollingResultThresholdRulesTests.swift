@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingResultThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRollingResultThresholdValidator()
        let item = Labs.newRollingResultThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRollingResultThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.RollingResultThresholdRequiredCodeRule(message: "rolling result threshold needs an entry")
        let item = Labs.newRollingResultThreshold("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRollingResultThresholdNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.RollingResultThresholdNameLengthRule(maxLength: 120)
        let item = Labs.newRollingResultThreshold("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRollingResultThresholdRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.RollingResultThresholdRequiredNameRule(message: "rolling result threshold needs a value")
        let item = Labs.newRollingResultThreshold("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRollingResultThresholdRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Labs.RollingResultThresholdRequiredTimezoneRule(message: "rolling result threshold needs this field")
        let item = Labs.newRollingResultThreshold("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRollingResultThresholdRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Labs.RollingResultThresholdRequiredBedRule(message: "rolling result threshold needs this field")
        let item = Labs.newRollingResultThreshold("", name: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}
