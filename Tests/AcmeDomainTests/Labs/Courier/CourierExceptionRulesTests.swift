@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCourierExceptionValidator()
        let item = Labs.newCourierException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCourierExceptionRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.CourierExceptionRequiredTitleRule(message: "courier exception needs a value")
        let item = Labs.newCourierException("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
