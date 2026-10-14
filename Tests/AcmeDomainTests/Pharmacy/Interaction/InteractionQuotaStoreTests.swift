@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionQuotaStore = Pharmacy.newMemoryInteractionQuotaStore()
        let item = Pharmacy.newInteractionQuota("code-949", label: "label-881")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
