@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFormularySegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FormularySegmentStore = Pharmacy.newMemoryFormularySegmentStore()
        let item = Pharmacy.newFormularySegment("code-990", label: "label-741")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
