@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionExceptionStore = Pharmacy.newMemoryInteractionExceptionStore()
        let item = Pharmacy.newInteractionException("code-853", label: "label-572")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
