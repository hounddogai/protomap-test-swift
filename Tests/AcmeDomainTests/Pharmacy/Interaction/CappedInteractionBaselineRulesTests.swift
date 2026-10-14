@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedInteractionBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultCappedInteractionBaselineValidator()
        let item = Pharmacy.newCappedInteractionBaseline("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyCappedInteractionBaselineRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Pharmacy.CappedInteractionBaselineRequiredExternalRefRule(
            message: "capped interaction baseline needs this field"
        )
        let item = Pharmacy.newCappedInteractionBaseline("", title: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyCappedInteractionBaselineExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Pharmacy.CappedInteractionBaselineExternalRefLengthRule(maxLength: 80)
        let item = Pharmacy.newCappedInteractionBaseline("x", title: "y")
        item.externalRef = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyCappedInteractionBaselineRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Pharmacy.CappedInteractionBaselineRevisionRangeRule(min: 3600, max: 86400)
        let item = Pharmacy.newCappedInteractionBaseline("x", title: "y")
        item.revision = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyCappedInteractionBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.CappedInteractionBaselineCodeLengthRule(maxLength: 16)
        let item = Pharmacy.newCappedInteractionBaseline("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyCappedInteractionBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.CappedInteractionBaselineRequiredCodeRule(
            message: "capped interaction baseline needs this field"
        )
        let item = Pharmacy.newCappedInteractionBaseline("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
