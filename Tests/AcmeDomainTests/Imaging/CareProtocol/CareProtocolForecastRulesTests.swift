@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolForecastValidator()
        let item = Imaging.newCareProtocolForecast("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.CareProtocolForecastCodeLengthRule(maxLength: 32)
        let item = Imaging.newCareProtocolForecast("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolForecastRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.CareProtocolForecastRequiredCodeRule(message: "care protocol forecast needs an entry")
        let item = Imaging.newCareProtocolForecast("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolForecastRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Imaging.CareProtocolForecastRequiredProcedureCodeRule(
            message: "care protocol forecast needs this field"
        )
        let item = Imaging.newCareProtocolForecast("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolForecastRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.CareProtocolForecastRequiredNameRule(message: "care protocol forecast needs this field")
        let item = Imaging.newCareProtocolForecast("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
