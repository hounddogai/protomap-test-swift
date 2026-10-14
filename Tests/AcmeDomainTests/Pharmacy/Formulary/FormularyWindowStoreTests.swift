@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFormularyWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FormularyWindowStore = Pharmacy.newMemoryFormularyWindowStore()
        let item = Pharmacy.newFormularyWindow("code-153", name: "name-221")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
