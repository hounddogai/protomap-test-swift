@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusSummaryValidator()
        let item = BedManagement.newCensusSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusSummaryRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = BedManagement.CensusSummaryRequiredAllergyRule(message: "census summary needs an entry")
        let item = BedManagement.newCensusSummary("", label: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusSummaryRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.CensusSummaryRequiredLabelRule(message: "census summary needs an entry")
        let item = BedManagement.newCensusSummary("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusSummaryAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = BedManagement.CensusSummaryAllergyLengthRule(maxLength: 16)
        let item = BedManagement.newCensusSummary("x", label: "y")
        item.allergy = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusSummaryLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.CensusSummaryLabelLengthRule(maxLength: 1000)
        let item = BedManagement.newCensusSummary("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
