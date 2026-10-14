@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryAdaptiveDispenseProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.AdaptiveDispenseProposalStore = Pharmacy.newMemoryAdaptiveDispenseProposalStore()
        let item = Pharmacy.newAdaptiveDispenseProposal("code-125", title: "title-66")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
