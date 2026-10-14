@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPrimaryInteractionBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PrimaryInteractionBaselineStore = Pharmacy.newMemoryPrimaryInteractionBaselineStore()
        let item = Pharmacy.newPrimaryInteractionBaseline("code-203", label: "label-167")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
