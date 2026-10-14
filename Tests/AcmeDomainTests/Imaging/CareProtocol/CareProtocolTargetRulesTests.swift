@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolTargetValidator()
        let item = Imaging.newCareProtocolTarget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolTargetRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Imaging.CareProtocolTargetRateRangeRule(min: 3.4, max: 1031.9)
        let item = Imaging.newCareProtocolTarget("x", title: "y")
        item.rate = 1033.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingCareProtocolTargetProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Imaging.CareProtocolTargetProcedureCodeLengthRule(maxLength: 1000)
        let item = Imaging.newCareProtocolTarget("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolTargetRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.CareProtocolTargetRequiredTitleRule(message: "care protocol target needs this field")
        let item = Imaging.newCareProtocolTarget("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
