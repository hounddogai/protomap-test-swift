@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryStrictInteractionBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.StrictInteractionBaselineStore = Pharmacy.newMemoryStrictInteractionBaselineStore()
        let item = Pharmacy.newStrictInteractionBaseline("code-389", label: "label-908")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
