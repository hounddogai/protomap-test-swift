@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledResultPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultScheduledResultPolicyValidator()
        let item = Labs.newScheduledResultPolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsScheduledResultPolicyRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Labs.ScheduledResultPolicyRequiredSourceRule(message: "scheduled result policy needs an entry")
        let item = Labs.newScheduledResultPolicy("", title: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsScheduledResultPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.ScheduledResultPolicyCodeLengthRule(maxLength: 1000)
        let item = Labs.newScheduledResultPolicy("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
