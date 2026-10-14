@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryStrictSubstitutionProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.StrictSubstitutionProposalStore = Pharmacy.newMemoryStrictSubstitutionProposalStore()
        let item = Pharmacy.newStrictSubstitutionProposal("code-368", name: "name-711")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
