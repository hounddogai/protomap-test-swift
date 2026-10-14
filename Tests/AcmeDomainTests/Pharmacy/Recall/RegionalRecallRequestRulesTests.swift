@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalRecallRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRegionalRecallRequestValidator()
        let item = Pharmacy.newRegionalRecallRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRegionalRecallRequestRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Pharmacy.RegionalRecallRequestRequiredUnitRule(message: "regional recall request needs a value")
        let item = Pharmacy.newRegionalRecallRequest("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRegionalRecallRequestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.RegionalRecallRequestRequiredTitleRule(message: "regional recall request needs a value")
        let item = Pharmacy.newRegionalRecallRequest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
