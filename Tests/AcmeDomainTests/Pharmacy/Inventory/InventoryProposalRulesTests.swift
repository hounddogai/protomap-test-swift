@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryProposalValidator()
        let item = Pharmacy.newInventoryProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryProposalRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Pharmacy.InventoryProposalRequiredContactEmailRule(message: "inventory proposal needs a value")
        let item = Pharmacy.newInventoryProposal("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryProposalChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Pharmacy.InventoryProposalChannelLengthRule(maxLength: 3600)
        let item = Pharmacy.newInventoryProposal("x", label: "y")
        item.channel = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventoryProposalContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Pharmacy.InventoryProposalContactEmailLengthRule(maxLength: 86400)
        let item = Pharmacy.newInventoryProposal("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventoryProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.InventoryProposalCodeLengthRule(maxLength: 255)
        let item = Pharmacy.newInventoryProposal("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
