@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPrimarySubstitutionAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PrimarySubstitutionAssignmentStore = Pharmacy.newMemoryPrimarySubstitutionAssignmentStore()
        let item = Pharmacy.newPrimarySubstitutionAssignment("code-348", label: "label-651")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
