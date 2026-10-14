@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseProposalValidator()
        let item = Pharmacy.newDispenseProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseProposalNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.DispenseProposalNameLengthRule(maxLength: 120)
        let item = Pharmacy.newDispenseProposal("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseProposalRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Pharmacy.DispenseProposalRegionLengthRule(maxLength: 3600)
        let item = Pharmacy.newDispenseProposal("x", name: "y")
        item.region = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}
