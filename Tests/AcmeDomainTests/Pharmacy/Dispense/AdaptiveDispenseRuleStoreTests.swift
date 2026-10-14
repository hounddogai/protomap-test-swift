@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryAdaptiveDispenseRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.AdaptiveDispenseRuleStore = Pharmacy.newMemoryAdaptiveDispenseRuleStore()
        let item = Pharmacy.newAdaptiveDispenseRule("code-736", title: "title-584")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
