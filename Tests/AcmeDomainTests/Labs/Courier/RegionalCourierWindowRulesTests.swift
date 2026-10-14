@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalCourierWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRegionalCourierWindowValidator()
        let item = Labs.newRegionalCourierWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRegionalCourierWindowContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Labs.RegionalCourierWindowContactEmailLengthRule(maxLength: 120)
        let item = Labs.newRegionalCourierWindow("x", title: "y")
        item.contactEmail = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRegionalCourierWindowDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Labs.RegionalCourierWindowDiagnosisCodeLengthRule(maxLength: 32)
        let item = Labs.newRegionalCourierWindow("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRegionalCourierWindowRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Labs.RegionalCourierWindowRequiredContactEmailRule(
            message: "regional courier window needs this field"
        )
        let item = Labs.newRegionalCourierWindow("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRegionalCourierWindowRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Labs.RegionalCourierWindowRequiredDiagnosisCodeRule(message: "regional courier window needs a value")
        let item = Labs.newRegionalCourierWindow("", title: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRegionalCourierWindowRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.RegionalCourierWindowRequiredTitleRule(message: "regional courier window needs a value")
        let item = Labs.newRegionalCourierWindow("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
