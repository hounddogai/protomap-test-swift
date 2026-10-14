@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryAdaptiveInteractionDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.AdaptiveInteractionDigestStore = Pharmacy.newMemoryAdaptiveInteractionDigestStore()
        let item = Pharmacy.newAdaptiveInteractionDigest("code-629", label: "label-67")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
