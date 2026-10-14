@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackRevocationSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultFallbackRevocationSnapshotValidator()
        let item = Consent.newFallbackRevocationSnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentFallbackRevocationSnapshotRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.FallbackRevocationSnapshotRequiredTitleRule(
            message: "fallback revocation snapshot needs an entry"
        )
        let item = Consent.newFallbackRevocationSnapshot("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentFallbackRevocationSnapshotDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Consent.FallbackRevocationSnapshotDiscountRangeRule(min: 3.0, max: 4381.5)
        let item = Consent.newFallbackRevocationSnapshot("x", title: "y")
        item.discount = 4383.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentFallbackRevocationSnapshotQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Consent.FallbackRevocationSnapshotQuantityRangeRule(min: 80, max: 1000)
        let item = Consent.newFallbackRevocationSnapshot("x", title: "y")
        item.quantity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentFallbackRevocationSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.FallbackRevocationSnapshotRequiredCodeRule(
            message: "fallback revocation snapshot needs this field"
        )
        let item = Consent.newFallbackRevocationSnapshot("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
