@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryWeightedSubstitutionProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.WeightedSubstitutionProposalStore = Pharmacy.newMemoryWeightedSubstitutionProposalStore()
        let item = Pharmacy.newWeightedSubstitutionProposal("code-895", title: "title-940")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
