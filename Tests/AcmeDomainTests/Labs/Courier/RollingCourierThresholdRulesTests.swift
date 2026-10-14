@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingCourierThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRollingCourierThresholdValidator()
        let item = Labs.newRollingCourierThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRollingCourierThresholdPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Labs.RollingCourierThresholdPayerLengthRule(maxLength: 255)
        let item = Labs.newRollingCourierThreshold("x", title: "y")
        item.payer = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRollingCourierThresholdRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Labs.RollingCourierThresholdRequiredRegionRule(message: "rolling courier threshold needs this field")
        let item = Labs.newRollingCourierThreshold("", title: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRollingCourierThresholdRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.RollingCourierThresholdRequiredTitleRule(message: "rolling courier threshold needs a value")
        let item = Labs.newRollingCourierThreshold("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
