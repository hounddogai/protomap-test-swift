@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDispenseAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DispenseAssignmentStore = Pharmacy.newMemoryDispenseAssignmentStore()
        let item = Pharmacy.newDispenseAssignment("code-231", label: "label-283")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
