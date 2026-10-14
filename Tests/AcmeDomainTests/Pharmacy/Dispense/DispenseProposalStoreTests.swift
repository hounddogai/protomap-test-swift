@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDispenseProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DispenseProposalStore = Pharmacy.newMemoryDispenseProposalStore()
        let item = Pharmacy.newDispenseProposal("code-360", name: "name-150")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
