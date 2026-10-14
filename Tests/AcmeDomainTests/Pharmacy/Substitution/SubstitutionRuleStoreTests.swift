@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySubstitutionRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SubstitutionRuleStore = Pharmacy.newMemorySubstitutionRuleStore()
        let item = Pharmacy.newSubstitutionRule("code-618", title: "title-969")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
