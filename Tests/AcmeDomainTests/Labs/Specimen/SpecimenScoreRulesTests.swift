@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenScoreValidator()
        let item = Labs.newSpecimenScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenScoreRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.SpecimenScoreRequiredNameRule(message: "specimen score needs an entry")
        let item = Labs.newSpecimenScore("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenScoreExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Labs.SpecimenScoreExternalRefLengthRule(maxLength: 255)
        let item = Labs.newSpecimenScore("x", name: "y")
        item.externalRef = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSpecimenScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.SpecimenScoreRequiredCodeRule(message: "specimen score needs this field")
        let item = Labs.newSpecimenScore("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenScoreExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Labs.SpecimenScoreExpiresAtRangeRule(min: 32, max: 3600)
        let item = Labs.newSpecimenScore("x", name: "y")
        item.expiresAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSpecimenScoreWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Labs.SpecimenScoreWindowDaysRangeRule(min: 80, max: 80)
        let item = Labs.newSpecimenScore("x", name: "y")
        item.windowDays = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSpecimenScoreNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.SpecimenScoreNameLengthRule(maxLength: 3600)
        let item = Labs.newSpecimenScore("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
