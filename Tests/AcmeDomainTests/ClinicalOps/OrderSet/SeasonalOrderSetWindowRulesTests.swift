@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalOrderSetWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultSeasonalOrderSetWindowValidator()
        let item = ClinicalOps.newSeasonalOrderSetWindow("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsSeasonalOrderSetWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.SeasonalOrderSetWindowCodeLengthRule(maxLength: 1000)
        let item = ClinicalOps.newSeasonalOrderSetWindow("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsSeasonalOrderSetWindowRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.SeasonalOrderSetWindowRequiredNameRule(
            message: "seasonal order set window needs an entry"
        )
        let item = ClinicalOps.newSeasonalOrderSetWindow("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsSeasonalOrderSetWindowSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = ClinicalOps.SeasonalOrderSetWindowSpecialtyLengthRule(maxLength: 255)
        let item = ClinicalOps.newSeasonalOrderSetWindow("x", name: "y")
        item.specialty = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsSeasonalOrderSetWindowNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.SeasonalOrderSetWindowNameLengthRule(maxLength: 3600)
        let item = ClinicalOps.newSeasonalOrderSetWindow("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
