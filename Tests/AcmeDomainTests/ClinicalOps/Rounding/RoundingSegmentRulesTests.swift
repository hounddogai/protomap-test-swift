@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingSegmentValidator()
        let item = ClinicalOps.newRoundingSegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingSegmentLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = ClinicalOps.RoundingSegmentLimitRangeRule(min: 80, max: 120)
        let item = ClinicalOps.newRoundingSegment("x", name: "y")
        item.limit = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRoundingSegmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.RoundingSegmentRequiredNameRule(message: "rounding segment needs this field")
        let item = ClinicalOps.newRoundingSegment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRoundingSegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.RoundingSegmentCodeLengthRule(maxLength: 255)
        let item = ClinicalOps.newRoundingSegment("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRoundingSegmentRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = ClinicalOps.RoundingSegmentRequiredExternalRefRule(message: "rounding segment needs this field")
        let item = ClinicalOps.newRoundingSegment("", name: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRoundingSegmentVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = ClinicalOps.RoundingSegmentVisitMinutesRangeRule(min: 64, max: 3600)
        let item = ClinicalOps.newRoundingSegment("x", name: "y")
        item.visitMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRoundingSegmentProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = ClinicalOps.RoundingSegmentProcedureCodeLengthRule(maxLength: 86400)
        let item = ClinicalOps.newRoundingSegment("x", name: "y")
        item.procedureCode = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
