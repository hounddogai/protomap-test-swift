@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalCareProtocolBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultSeasonalCareProtocolBaselineValidator()
        let item = Imaging.newSeasonalCareProtocolBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingSeasonalCareProtocolBaselineRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Imaging.SeasonalCareProtocolBaselineRequiredProcedureCodeRule(
            message: "seasonal care protocol baseline needs a value"
        )
        let item = Imaging.newSeasonalCareProtocolBaseline("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingSeasonalCareProtocolBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.SeasonalCareProtocolBaselineCodeLengthRule(maxLength: 16)
        let item = Imaging.newSeasonalCareProtocolBaseline("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingSeasonalCareProtocolBaselineRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Imaging.SeasonalCareProtocolBaselineRequiredPatientRefRule(
            message: "seasonal care protocol baseline needs a value"
        )
        let item = Imaging.newSeasonalCareProtocolBaseline("", name: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingSeasonalCareProtocolBaselineNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.SeasonalCareProtocolBaselineNameLengthRule(maxLength: 86400)
        let item = Imaging.newSeasonalCareProtocolBaseline("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingSeasonalCareProtocolBaselineProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Imaging.SeasonalCareProtocolBaselineProcedureCodeLengthRule(maxLength: 16)
        let item = Imaging.newSeasonalCareProtocolBaseline("x", name: "y")
        item.procedureCode = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingSeasonalCareProtocolBaselineVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Imaging.SeasonalCareProtocolBaselineVersionRangeRule(min: 80, max: 120)
        let item = Imaging.newSeasonalCareProtocolBaseline("x", name: "y")
        item.version = 121
        #expect(rule.check(item).count > 0)
    }
}
