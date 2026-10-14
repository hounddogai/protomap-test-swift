@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySubstitutionAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SubstitutionAssignmentStore = Pharmacy.newMemorySubstitutionAssignmentStore()
        let item = Pharmacy.newSubstitutionAssignment("code-783", title: "title-496")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
