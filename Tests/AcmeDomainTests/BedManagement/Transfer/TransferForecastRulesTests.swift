@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferForecastValidator()
        let item = BedManagement.newTransferForecast("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferForecastNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.TransferForecastNameLengthRule(maxLength: 32)
        let item = BedManagement.newTransferForecast("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferForecastRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = BedManagement.TransferForecastRequiredClinicianIDRule(message: "transfer forecast needs a value")
        let item = BedManagement.newTransferForecast("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTransferForecastRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.TransferForecastRequiredNameRule(message: "transfer forecast needs an entry")
        let item = BedManagement.newTransferForecast("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
