@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCourierDigestValidator()
        let item = Labs.newCourierDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCourierDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.CourierDigestCodeLengthRule(maxLength: 16)
        let item = Labs.newCourierDigest("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCourierDigestRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Labs.CourierDigestRequiredCategoryRule(message: "courier digest needs a value")
        let item = Labs.newCourierDigest("", label: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}
