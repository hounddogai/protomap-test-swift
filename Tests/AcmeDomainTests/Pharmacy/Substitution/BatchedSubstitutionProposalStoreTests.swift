@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryBatchedSubstitutionProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.BatchedSubstitutionProposalStore = Pharmacy.newMemoryBatchedSubstitutionProposalStore()
        let item = Pharmacy.newBatchedSubstitutionProposal("code-401", name: "name-640")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
