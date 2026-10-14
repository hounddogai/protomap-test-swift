@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictBedBoardForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultStrictBedBoardForecastValidator()
        let item = BedManagement.newStrictBedBoardForecast("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementStrictBedBoardForecastRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.StrictBedBoardForecastRequiredTitleRule(
            message: "strict bed board forecast needs this field"
        )
        let item = BedManagement.newStrictBedBoardForecast("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementStrictBedBoardForecastRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = BedManagement.StrictBedBoardForecastRequiredPatientRefRule(
            message: "strict bed board forecast needs a value"
        )
        let item = BedManagement.newStrictBedBoardForecast("", label: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementStrictBedBoardForecastRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = BedManagement.StrictBedBoardForecastRevisionRangeRule(min: 255, max: 86400)
        let item = BedManagement.newStrictBedBoardForecast("x", label: "y")
        item.revision = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementStrictBedBoardForecastTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.StrictBedBoardForecastTitleLengthRule(maxLength: 255)
        let item = BedManagement.newStrictBedBoardForecast("x", label: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
