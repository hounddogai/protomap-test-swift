@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFormularyAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FormularyAssignmentStore = Pharmacy.newMemoryFormularyAssignmentStore()
        let item = Pharmacy.newFormularyAssignment("code-611", name: "name-381")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
