@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDispenseRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DispenseRuleStore = Pharmacy.newMemoryDispenseRuleStore()
        let item = Pharmacy.newDispenseRule("code-151", name: "name-596")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
