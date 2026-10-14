@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFallbackSubstitutionProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FallbackSubstitutionProposalStore = Pharmacy.newMemoryFallbackSubstitutionProposalStore()
        let item = Pharmacy.newFallbackSubstitutionProposal("code-692", label: "label-158")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
